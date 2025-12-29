# Debug Available Sliders

## Problème Actuel

Les sliders "Available Movies" et "Available TV" affichent "Failed to load content" dans l'app.

## Cause Probable

D'après les logs :
```
📊 Loaded 18 sliders from server
   ✅ Enabled: 15
   ❌ Disabled: 3
```

Les sliders Available Movies (type 24) et Available TV (type 25) sont probablement **désactivés** côté serveur.

## Solution

### Étape 1: Vérifier la configuration serveur

Connectez-vous à votre serveur Seerr et vérifiez l'API :

```bash
curl -X GET "http://192.168.1.46:5055/api/v1/settings/discover" \
  -H "X-Api-Key: VOTRE_API_KEY" \
  -H "Accept: application/json"
```

Cherchez dans la réponse :
```json
{
  "id": "...",
  "type": 24,
  "title": "Available Movies",
  "enabled": false  <-- DEVRAIT ÊTRE true
}
```

### Étape 2: Activer les sliders

**Via l'interface web :**
1. Ouvrez http://192.168.1.46:5055
2. Allez dans **Settings** → **Discover**
3. Trouvez "Available Movies" dans la colonne "Available Sliders" (droite)
4. **Glissez-le** vers la colonne "Enabled Sliders" (gauche)
5. Répétez pour "Available TV"
6. Cliquez **Save Changes**

**Via l'API (avancé) :**
```bash
# Récupérer la config actuelle
curl -X GET "http://192.168.1.46:5055/api/v1/settings/discover" \
  -H "X-Api-Key: VOTRE_API_KEY" > sliders.json

# Éditer sliders.json et changer "enabled": false à "enabled": true
# pour les types 24 et 25

# Sauvegarder
curl -X POST "http://192.168.1.46:5055/api/v1/settings/discover" \
  -H "X-Api-Key: VOTRE_API_KEY" \
  -H "Content-Type: application/json" \
  -d @sliders.json
```

### Étape 3: Vérifier que vous avez des médias disponibles

Les sliders seront vides si vous n'avez pas de médias avec status AVAILABLE (5) ou PARTIALLY_AVAILABLE (4).

**Vérifier via l'API :**
```bash
# Vérifier les films disponibles
curl -X GET "http://192.168.1.46:5055/api/v1/available/movies?type=movie&page=1" \
  -H "X-Api-Key: VOTRE_API_KEY" \
  -H "Accept: application/json"

# Vérifier les séries disponibles
curl -X GET "http://192.168.1.46:5055/api/v1/available/movies?type=tv&page=1" \
  -H "X-Api-Key: VOTRE_API_KEY" \
  -H "Accept: application/json"
```

**Réponse attendue :**
```json
{
  "page": 1,
  "totalPages": 3,
  "totalResults": 55,
  "results": [
    {
      "id": 550,
      "mediaType": "movie",
      "title": "Fight Club",
      "posterPath": "/...",
      "mediaInfo": {
        "status": 5,  <-- AVAILABLE
        "mediaAddedAt": "2025-01-20T15:30:00.000Z"
      }
    }
  ]
}
```

Si `"results": []` est vide, c'est normal que les sliders soient vides.

### Étape 4: Redémarrer l'app

1. **Force quit** Molyseerr (double-clic bouton TV, swipe up sur l'app)
2. **Relancer** l'app
3. L'app va recharger la config des sliders

## Diagnostic Rapide

### Test 1: Vérifier que l'endpoint fonctionne

```bash
curl -X GET "http://192.168.1.46:5055/api/v1/available/movies?type=movie&page=1" \
  -H "X-Api-Key: VOTRE_API_KEY" | jq '.totalResults'
```

Si retourne `0` → Pas de films disponibles dans votre bibliothèque
Si retourne un nombre > 0 → L'API fonctionne, le problème vient de l'activation du slider

### Test 2: Vérifier la config des sliders

```bash
curl -X GET "http://192.168.1.46:5055/api/v1/settings/discover" \
  -H "X-Api-Key: VOTRE_API_KEY" | jq '.[] | select(.type == 24 or .type == 25)'
```

**Réponse attendue :**
```json
{
  "id": "abc123",
  "type": 24,
  "title": "Available Movies",
  "enabled": true,  <-- DOIT ÊTRE true
  "data": null
}
{
  "id": "def456",
  "type": 25,
  "title": "Available TV",
  "enabled": true,  <-- DOIT ÊTRE true
  "data": null
}
```

## Logs de Debug

Pour activer plus de logs dans l'app, ajoutez dans DiscoverView.swift :

```swift
case .available(let mediaType):
    print("🔍 DEBUG: Fetching available media for type: \(mediaType.rawValue)")
    let response = try await service.getAvailableMedia(
        type: mediaType.rawValue,
        page: 1,
        sortBy: "mediaAddedAt"
    )
    print("✅ DEBUG: Received \(response.results.count) available \(mediaType.rawValue) items")
    return Array(response.results.prefix(20))
```

## Questions Fréquentes

### Q: Les sliders apparaissent mais sont vides ?
**R:** Normal si vous n'avez pas encore de médias téléchargés. Demandez un film via l'app et attendez qu'il soit téléchargé (status = 5).

### Q: Les sliders n'apparaissent pas du tout ?
**R:** Ils sont désactivés côté serveur. Suivez les étapes ci-dessus pour les activer.

### Q: J'ai des films téléchargés mais les sliders sont vides ?
**R:** Vérifiez le status des médias dans Seerr web → Media. Le status doit être "Available" (vert) ou "Partially Available" (violet), pas "Pending" ou "Processing".

### Q: L'app crash quand j'accède aux sliders ?
**R:** Vérifiez la console Xcode pour voir l'erreur exacte. Probablement un problème de décodage JSON.

## Support

Si le problème persiste :
1. Capturez les logs Xcode complets
2. Testez les endpoints manuellement avec curl
3. Vérifiez la version de Seerr (devrait être v3.0+)
4. Ouvrez une issue avec tous les détails

---

**Dernière mise à jour :** 2025-12-29
