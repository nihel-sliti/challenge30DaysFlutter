# day05_storeApp

A new Flutter project.

# New Trend Store 🛒

Application Flutter de catalogue produits basée sur une **architecture Clean** et le **state management BLoC**.  
L’app consomme une **API publique** (Fake Store / collection Postman) pour :

- **Lister tous les produits** sous forme de grille
- **Créer un nouveau produit** via un formulaire dédié (vue admin)

---

## 📱 Aperçu

| Liste des produits | Ajout d’un produit |
| ------------------ | ------------------ |
| ![Product Grid]<img width="383" height="862" alt="image" src="https://github.com/user-attachments/assets/af4b7007-290e-400e-b851-1054d8cea40a" />
 | ![Add Product]<img width="377" height="833" alt="image" src="https://github.com/user-attachments/assets/610e810e-cb79-4ff4-a180-32db8def4172" />
 |

*(Remplacer par tes propres captures d’écran dans `screenshots/`)*

---

## ✨ Fonctionnalités

- Affichage des produits en **GridView.builder**
- Carte produit avec :
  - image
  - catégorie
  - titre
  - prix
  - note + nombre d’avis
- Écran **“Add Product”** :
  - Titre
  - Prix
  - Description
  - Catégorie
  - URL de l’image
  - Note (0–5)
  - Nombre de reviews
- Gestion d’état avec **BLoC (Event / State / Bloc)**
- Séparation claire :
  - **Service** réseau pour appeler l’API
  - **Model** / **Repository** / **UI**

---

## 🏗 Architecture

L’application suit une approche **Clean Architecture + BLoC**.

### Couches principales

- **presentation/**
  - Écrans (`ProductListPage`, `AddProductPage`)
  - Widgets UI (`ProductCard`, etc.)
  - `ProductBloc`, `ProductEvent`, `ProductState`
- **data/**
  - `ProductModel` (mapping JSON ↔ Dart)
  - `ProductService` (appel HTTP à l’API publique)
  - Repository d’implémentation
- **domain/** (optionnel selon ton projet)
  - Entités & use cases (`GetAllProducts`, `AddProduct`)

### BLoC

- `ProductEvent`
  - `LoadProductsEvent`
  - `AddProductEvent`
- `ProductState`
  - `ProductInitial`
  - `ProductLoading`
  - `ProductLoaded`
  - `ProductError`

Dans l’UI, l’état est consommé via :

```dart
BlocBuilder<ProductBloc, ProductState>(
  builder: (context, state) {
    // affichage des états: loading, liste, erreur...
  },
);

