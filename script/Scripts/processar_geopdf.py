from osgeo import gdal, osr, ogr
import json
import os
import subprocess
import sys
import zipfile

gdal.UseExceptions()
DPI = "DPI=192"

if len(sys.argv) > 1:
    pdf_path = sys.argv[1]
else:
    comando = [
        "powershell.exe",
        "-NoProfile",
        "-Command",
        (
            "Add-Type -AssemblyName System.Windows.Forms; "
            "$dialog = New-Object System.Windows.Forms.OpenFileDialog; "
            "$dialog.InitialDirectory = 'C:\\Users\\'; "
            "$dialog.Filter = 'GeoPDF (*.pdf)|*.pdf'; "
            "if ($dialog.ShowDialog() -eq 'OK') { "
            "Write-Output $dialog.FileName "
            "}"
        )
    ]

    resultado = subprocess.run(
        comando,
        capture_output=True,
        text=True
    )

    pdf_path = resultado.stdout.strip()

    if not pdf_path:
        print("Nenhum arquivo selecionado.")
        sys.exit(0)
        

nome = os.path.splitext(os.path.basename(pdf_path))[0]

png_path = os.path.join(os.path.dirname(pdf_path), nome + ".png")
json_path = os.path.join(os.path.dirname(pdf_path), nome + ".json")


# ==============================================================================
# PARTE RASTER (IMAGEM E GEORREFERENCIAMENTO)
# ==============================================================================

# Abre o GeoPDF como Raster
dataset = gdal.OpenEx(
    pdf_path,
    gdal.OF_RASTER,
    open_options=[DPI]
)

if dataset is None:
    print("Erro: não foi possível abrir o GeoPDF como Raster.")
    sys.exit(1)


# Informações da imagem
width = dataset.RasterXSize
height = dataset.RasterYSize

# Georreferenciamento
geotransform = dataset.GetGeoTransform()
projection = dataset.GetProjection()

if not projection:
    print("ERRO!\nPDF não possui projeções. *dados que possibilitem geo posicionar ele em um mapa.*")
    sys.exit(1)

# Conversão para lat/lng
srs = osr.SpatialReference()
srs.ImportFromWkt(projection)
srs.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)

destino = osr.SpatialReference()
destino.ImportFromEPSG(4326)
destino.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)

transformacao = osr.CoordinateTransformation(srs, destino)

def para_latlng(x, y):
    lng, lat, _ = transformacao.TransformPoint(x, y)
    return {"lat": lat, "lng": lng}

def pixel_para_geo(col, row):
    x = geotransform[0] + col * geotransform[1] + row * geotransform[2]
    y = geotransform[3] + col * geotransform[4] + row * geotransform[5]
    return x, y

# Os 4 cantos
upper_left  = para_latlng(*pixel_para_geo(0, 0))
upper_right = para_latlng(*pixel_para_geo(width, 0))
lower_right = para_latlng(*pixel_para_geo(width, height))
lower_left  = para_latlng(*pixel_para_geo(0, height))


# Gera PNG
gdal.Translate(
    png_path,
    dataset,
    format="PNG"
)

# Fecha o dataset raster para liberar memória
dataset = None


# ==============================================================================
# PARTE VETORIAL (EXTRAÇÃO DINÂMICA DE CAMADAS)
# ==============================================================================

dados_vetores = {}
nomes_camadas = set()

try:
    vec_dataset = gdal.OpenEx(
        pdf_path,
        gdal.OF_VECTOR,
        open_options=["OGR_PDF_READ_NON_STRUCTURED=YES"]
    )

    if vec_dataset is not None:
        for i in range(vec_dataset.GetLayerCount()):

            layer = vec_dataset.GetLayer(i)
            layer_name = layer.GetName()

            # Ajusta o nome para não ter camadas com nomes duplicados:
            nome_original = layer_name
            if layer_name in nomes_camadas:
                contador = 2

                while f"{nome_original}_{contador:02d}" in nomes_camadas:
                    contador += 1

                layer_name = f"{nome_original}_{contador:02d}"
                print(
                    f'Aviso: camada com nome repetido "{nome_original}". '
                    f'Esta ocorrência será identificada como "{layer_name}".'
                )

            nomes_camadas.add(layer_name)
            

            # SRS da própria camada; se não tiver, usa o do raster
            srs_camada = layer.GetSpatialRef()
            if srs_camada is not None:
                srs_camada = srs_camada.Clone()
                srs_camada.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)
                transf_camada = osr.CoordinateTransformation(srs_camada, destino)

            else:
                # Se a camada não informou qual 
                # o tipo de coordenada ela usa, 
                # assumesse que ela usa a mesma do raster!
                # Se as coordenadas dos pontos estiverem
                # claramente deslocadas, vale analisar analisar se
                # a camada de pontos usa uma tipo de coordenada diferente
                # do raster, e não é passado o tipo dela no geoPDF.
                transf_camada = transformacao

            pontos = []
            layer.ResetReading()
            fields_def = layer.GetLayerDefn()

            for feature in layer:
                geom = feature.GetGeometryRef()

                # Só POINT: linhas e polígonos são ignorados
                if geom is None or geom.GetGeometryName() != "POINT":
                    continue

                propriedades = {}
                for f_idx in range(fields_def.GetFieldCount()):
                    nome_campo = fields_def.GetFieldDefn(f_idx).GetName()
                    propriedades[nome_campo] = feature.GetField(f_idx)

                lng, lat, _ = transf_camada.TransformPoint(geom.GetX(), geom.GetY())

                pontos.append({
                    "propriedades": propriedades,
                    "coordenadas": {"lat": lat, "lng": lng}
                })

            # Descarta camadas sem nenhum ponto
            if pontos:
                dados_vetores[layer_name] = pontos

except Exception as e:
    print(f"Aviso ao ler dados vetoriais (pode não conter vetores): {e}")


# ==============================================================================
#  MONTAGEM E SALVAMENTO DO JSON FINAL
# ==============================================================================

dados = {
    "image": os.path.basename(png_path),
    "corners": {
        "upperLeft": upper_left,
        "upperRight": upper_right,
        "lowerRight": lower_right,
        "lowerLeft": lower_left
    },
    "vetores": dados_vetores
}


# Salva JSON
with open(json_path, "w", encoding="utf-8") as arquivo:
    json.dump(dados, arquivo, indent=4, ensure_ascii=False)


print("Concluído!")
print(f"PNG:  {png_path}")
print(f"JSON: {json_path}")

print("Zipando PNG + JSON")

zip_path = os.path.join(
    os.path.dirname(pdf_path),
    nome + ".zip"
)

with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
    zipf.write(png_path, os.path.basename(png_path))
    zipf.write(json_path, os.path.basename(json_path))

print(f"ZIP: {zip_path}")

#==============================
# LIMPAR ARQUIVOS TEMPORÁRIOS
#==============================
print("Limpando arquivos temporários soltos...")

arquivos_temporarios = [
    png_path,
    json_path,
    png_path + ".aux.xml",
    pdf_path + ".aux.xml"
]

for arquivo in arquivos_temporarios:
    if os.path.exists(arquivo):
        os.remove(arquivo)

print("Arquivos temporários apagados.")

print("Processo finalizado!...")
# exit(0)