# Geo Foto

## Sobre o projeto
O projeto Geo Foto foi desenvolvido a partir da demanda que surgiu durante o período de estágio no CENSIPAM (Centro Gestor e Operacional do Sistema de Proteção da Amazônia), com o objetivo de atender às necessidades operacionais do NUHIDRO (Núcleo de Hidrologia).

O projeto é composto por:
- um **aplicativo Flutter**;
- um **script** que processa GeoPDFs e entrega ao app apenas a imagem `.png` e os dados em `.json`, extraídos do PDF por meio da biblioteca `gdal`.

## Decisões de projeto

### Por que processar o GeoPDF fora do celular?
Os dispositivos móveis não têm, nativamente, a capacidade de processar GeoPDFs. O `gdal` é uma biblioteca nativa de Linux, e não bastaria importá-la no app: o sistema do smartphone não saberia executá-la. Por isso, o processamento é feito por um script externo, e o app recebe só o resultado pronto (`.png` + `.json`).

### Por que Miniforge?
Para evitar a abertura de chamados para instalar Linux (como o WSL) nas máquinas dos servidores, e porque não era necessário tudo o que vem com uma distribuição Linux completa, foi escolhido o Miniforge: mais simples e sem exigir senha de administrador para instalar.


A documentação do script está disponível ao final deste documento.

## Flutter

### Visão geral
O app Geo Foto permite registrar fotos em campo vinculadas a pontos de interesse sobre um mapa georreferenciado. Cada foto é salva com os metadados sobrepostos na imagem e é possível comparar, no relatório, o local planejado com o local real onde ela foi tirada.

### Fluxo de uso
1. **Criar missão**
2. **Importar o mapa** (o `.png` + `.json` gerados pelo script)
3. **Importar ou não a camada de pontos**
4. **Abrir o mapa**, criar pontos e selecionar um ponto para registrar a foto
5. **Tirar a foto**: ela é salva com overlay de metadados e, se necessário, observações

As fotos seguem um padrão de nomenclatura sequencial, configurável como letras (A, B, C...) ou números (1, 2, 3...).

### Funcionalidades
- **Relatório em CSV** com os dados de cada foto e a distância entre o local onde ela foi tirada e o ponto escolhido
- **Filtros** por ponto, missão ou nome
- **Compartilhamento** das fotos selecionadas por qualquer app, usando o `share_plus`

### Instalação

#### Usuário final
1. Baixe o APK na aba [Releases](https://github.com/NotlistForU/geo_foto/releases/tag/APK)
2. Permita a instalação de fontes desconhecidas no celular
3. Instale e abra o app

> Para gerar os mapas, veja a documentação do script no fim deste documento.

#### Desenvolvimento
Pré-requisitos, clone, `flutter pub get` e `flutter run` com depuração USB.


## Script de processamento de GeoPDF
Gera o ZIP (`.png` + `.json`) que o app importa.
Documentação completa em [`script/README.md`](script/README.md).
