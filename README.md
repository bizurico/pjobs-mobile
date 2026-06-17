# PJobs

O **PJobs** é uma plataforma mobile desenvolvida para conectar clientes a profissionais prestadores de serviços de forma rápida, eficiente e descentralizada. O aplicativo gerencia todo o fluxo de demandas, desde a solicitação inicial com registro visual do problema até a conclusão do serviço com comprovação por imagem, além de mapeamento espacial para localização e atendimento.

## 📱 Tela Inicial do Aplicativo

<p align="center">
  <img src="screenshot.png" alt="Tela Inicial do PJobs" width="300px">
</p>

---

## 🛠️ Tecnologias Utilizadas

O projeto foi construído utilizando um ecossistema moderno focado em alta performance mobile e persistência de dados em tempo real:

* **Front-end & Mobile:**
    * [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/) — Framework multiplataforma principal.
    * `flutter_typeahead` — Sistema de sugestões e preenchimento preditivo de texto.
    * `image_picker` — Integração nativa com a câmera e galeria do dispositivo móvel.

* **Back-end & Infraestrutura (BaaS):**
    * [Firebase Authentication](https://firebase.google.com/docs/auth) — Controle de sessões e autenticação segura de usuários.
    * [Cloud Firestore](https://firebase.google.com/docs/firestore) — Banco de dados NoSQL baseado em documentos com sincronização em tempo real.

* **APIs & Serviços Externos:**
    * `Google Maps SDK for Android` — Renderização de mapas nativos.
    * `Google Places API` — Motor HTTP de sugestão e autocompletar de endereços estruturados no Brasil.
    * `url_launcher` — Despacho de intenções nativas para abertura de rotas em aplicativos externos.

---

## 👥 Integrantes da Equipe

1.  **Luis Henrique Soares de Oliveira**
2.  **Bruno Eduardo de Menezes Lima Filho**

---

## 🚀 Instruções Básicas de Execução

Siga os passos abaixo para clonar o repositório e executar o projeto em seu ambiente de desenvolvimento ou dispositivo físico:

### Pré-requisitos
* Flutter SDK instalado e configurado (versão estável estável estável).
* Um dispositivo Android com o Modo de Depuração USB ativado ou um emulador configurado.

### Passos para Execução

1.  **Clonar o repositório:**
    ```bash
    git clone [https://github.com/SEU_USUARIO_GITHUB/pjobs.git](https://github.com/SEU_USUARIO_GITHUB/pjobs.git)
    ```
2.  **Acessar a pasta do projeto:**
    ```bash
    cd pjobs
    ```
3.  **Instalar os pacotes e dependências do Flutter:**
    ```bash
    flutter pub get
    ```
4.  **Executar o aplicativo em modo de depuração (debug):**
    ```bash
    flutter run
    ```
