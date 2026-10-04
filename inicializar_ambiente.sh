#!/usr/bin/env bash

if ! command -v docker >/dev/null 2>&1; then
    echo "[ERRO] Docker não está instalado."
    echo "Instale o Docker para prosseguir."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Iniciando o Docker..."

    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl start docker || {
            echo "[ERRO] Não foi possível iniciar o Docker."
            exit 1
        }
    elif command -v service >/dev/null 2>&1; then
        sudo service docker start || {
            echo "[ERRO] Não foi possível iniciar o Docker."
            exit 1
        }
    else
        echo "[ERRO] Não foi possível encontrar systemctl ou service para iniciar o Docker."
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        echo "[ERRO] O serviço Docker não ficou ativo."
        exit 1
    fi
fi

echo "Qual ambiente deseja iniciar?"
select opcao in "Integração e Entrega Contínua (CI/CD)" "Desenvolvimento"; do
    case "$REPLY" in
        1)
            docker compose --profile dev stop || exit 1
            docker compose --profile ic up -d || exit 1
            break
            ;;
        2)
            docker compose --profile ic stop || exit 1
            docker compose --profile dev up -d || exit 1
            break
            ;;
        *)
            echo "Opção inválida. Digite 1 ou 2."
            ;;
    esac
done
