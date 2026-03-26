#!/bin/bash

FASTPEN_CONECTED='mount | grep FASTPEN'

if [ -z "$FASTPEN_CONECTED" ]; then
   echo "Conectado"
else
   echo "Nao Conectado"
fi
