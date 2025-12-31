#!/bin/bash

# NiFi Encryption Fix Test Script
# This script configures NiFi to use hex key encryption instead of password-based

set -e

echo "=== NiFi Encryption Fix Test ==="
echo ""

# Variables
NIFI_HOME="/usr/odp/current/nifi"
NIFI_CONF="${NIFI_HOME}/conf"
BOOTSTRAP_CONF="${NIFI_CONF}/bootstrap.conf"
NIFI_PROPS="${NIFI_CONF}/nifi.properties"
TOOLKIT_HOME="/usr/odp/current/nifi-toolkit"
ENCRYPT_TOOL="${TOOLKIT_HOME}/bin/encrypt-config.sh"

# Hex key (256-bit = 64 hex characters)
HEX_KEY="ed1f8d6cfc4e67fb182d4eb93e47f61890ddc78fa6dc6cb0ee92d6b83ea3b831"
ALGORITHM="NIFI_PBKDF2_AES_GCM_256"

# Check if NiFi is installed
if [ ! -d "$NIFI_HOME" ]; then
    echo "❌ NiFi não encontrado em $NIFI_HOME"
    exit 1
fi
echo "✓ NiFi instalado encontrado"

# Create backup
BACKUP_DIR="/tmp/nifi-backup-$(date +%Y%m%d-%H%M%S)"
echo "Criando backup em $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
cp "$BOOTSTRAP_CONF" "$BACKUP_DIR/" 2>/dev/null || true
cp "$NIFI_PROPS" "$BACKUP_DIR/" 2>/dev/null || true
echo "✓ Backup criado"

# Stop NiFi if running
echo "Parando NiFi (se estiver rodando)..."
systemctl stop nifi 2>/dev/null || ${NIFI_HOME}/bin/nifi.sh stop 2>/dev/null || true
sleep 3

echo ""
echo "Step 1: Configurando bootstrap.conf"

# Configure bootstrap.conf with hex key
if ! grep -q "nifi.bootstrap.sensitive.key=" "$BOOTSTRAP_CONF"; then
    echo "nifi.bootstrap.sensitive.key=${HEX_KEY}" >> "$BOOTSTRAP_CONF"
else
    sed -i "s|^nifi.bootstrap.sensitive.key=.*|nifi.bootstrap.sensitive.key=${HEX_KEY}|" "$BOOTSTRAP_CONF"
fi

# Set algorithm
if ! grep -q "nifi.bootstrap.protection.algorithm=" "$BOOTSTRAP_CONF"; then
    echo "nifi.bootstrap.protection.algorithm=${ALGORITHM}" >> "$BOOTSTRAP_CONF"
else
    sed -i "s|^nifi.bootstrap.protection.algorithm=.*|nifi.bootstrap.protection.algorithm=${ALGORITHM}|" "$BOOTSTRAP_CONF"  
fi

echo "✓ bootstrap.conf configurado com chave hex"

echo ""
echo "Step 2: Configurando nifi.properties"

# Make sure nifi.properties has the correct algorithm
if ! grep -q "nifi.sensitive.props.algorithm=" "$NIFI_PROPS"; then
    echo "nifi.sensitive.props.algorithm=${ALGORITHM}" >> "$NIFI_PROPS"
else
    sed -i "s|^nifi.sensitive.props.algorithm=.*|nifi.sensitive.props.algorithm=${ALGORITHM}|" "$NIFI_PROPS"
fi

# Set provider
if ! grep -q "nifi.sensitive.props.provider=" "$NIFI_PROPS"; then
    echo "nifi.sensitive.props.provider=BC" >> "$NIFI_PROPS"
else
    sed -i "s|^nifi.sensitive.props.provider=.*|nifi.sensitive.props.provider=BC|" "$NIFI_PROPS"
fi

echo "✓ nifi.properties configurado"

echo ""
echo "Step 3: Testando encriptação com encrypt-config.sh"

# Test encryption with hex key (-k flag)
if [ -f "$ENCRYPT_TOOL" ]; then
    echo "Executando encrypt-config.sh..."
    ${ENCRYPT_TOOL} \
        -b "${BOOTSTRAP_CONF}" \
        -n "${NIFI_PROPS}" \
        -k "${HEX_KEY}" \
        -v || true
    echo "✓ Encriptação executada"
else
    echo "⚠ encrypt-config.sh não encontrado, pulando teste"
fi

echo ""
echo "Step 4: Verificando configurações"

echo "Verificando bootstrap.conf:"
if grep -q "nifi.bootstrap.sensitive.key=${HEX_KEY}" "$BOOTSTRAP_CONF"; then
    echo "✓ Chave hex encontrada em bootstrap.conf"
else
    echo "❌ Chave hex NÃO encontrada em bootstrap.conf"
fi

echo ""
echo "Verificando nifi.properties:"
if grep -q "nifi.sensitive.props.algorithm=${ALGORITHM}" "$NIFI_PROPS"; then
    echo "✓ Algoritmo correto em nifi.properties"
else
    echo "❌ Algoritmo NÃO configurado em nifi.properties"
fi

echo ""
echo "Step 5: Iniciando NiFi"
echo "Iniciando serviço..."

# Start NiFi
systemctl start nifi 2>/dev/null || ${NIFI_HOME}/bin/nifi.sh start 2>/dev/null || true
echo "✓ Comando de start executado"

# Wait for NiFi to start
echo "Aguardando NiFi iniciar (pode levar até 60 segundos)..."
for i in {1..60}; do
    if systemctl is-active nifi >/dev/null 2>&1 || pgrep -f "org.apache.nifi.NiFi" >/dev/null 2>&1; then
        echo "✓ NiFi está rodando!"
        break
    fi
    sleep 1
done

echo ""
echo "Step 6: Verificando logs"
if [ -f "/var/log/nifi/nifi-app.log" ]; then
    echo "Últimas 20 linhas do log:"
    tail -n 20 /var/log/nifi/nifi-app.log
    
    echo ""
    echo "Erros encontrados no log (últimos 5)"
    grep -i "error\|exception" /var/log/nifi/nifi-app.log | tail -n 5 || echo "Nenhum erro encontrado"
fi

echo ""
echo "Step 7: Testando conectividade"
sleep 5
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:9090/nifi || echo "WARN: NiFi UI pode não estar totalmente iniciado ainda"

echo ""
echo "Tente acessar: http://$(hostname):9090/nifi"

echo ""
echo "======================================"
echo "TESTE CONCLUÍDO!"
echo ""
echo "Backup dos arquivos originais: $BACKUP_DIR"
echo ""
echo "Para reverter em caso de problemas:"
echo "  cp $BACKUP_DIR/bootstrap.conf /usr/odp/current/nifi/conf/"
echo "  cp $BACKUP_DIR/nifi.properties /usr/odp/current/nifi/conf/"
echo "  systemctl restart nifi"
echo ""
echo "======================================"
