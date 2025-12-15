#!/bin/bash

# Chemin vers votre projet
PROJECT_DIR="/home/amyv4492/easykonect.smil-app.com/easykonect_prod"
LOG_FILE="$PROJECT_DIR/storage/logs/worker.log"

# Aller dans le répertoire du projet
cd $PROJECT_DIR || exit 1

# Fonction pour redémarrer le worker
restart_worker() {
    # Tuer les anciens workers
    pkill -f "queue:work" 2>/dev/null
    
    # Attendre un peu
    sleep 2
    
    # Lancer le nouveau worker en arrière-plan
    nohup php artisan queue:work --sleep=3 --tries=3 --max-time=3600 > $LOG_FILE 2>&1 &
    
    echo "Worker redémarré à $(date)" >> $LOG_FILE
    echo "PID: $!" >> $LOG_FILE
}

# Lancer le worker
restart_worker

# Boucle infinie pour surveiller et redémarrer si nécessaire
while true; do
    sleep 60  # Vérifier toutes les minutes
    
    # Vérifier si le worker tourne toujours
    if ! pgrep -f "queue:work" > /dev/null; then
        echo "Worker arrêté, redémarrage à $(date)..." >> $LOG_FILE
        restart_worker
    fi
done
