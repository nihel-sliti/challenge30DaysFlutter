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
|<img width="383" height="862" alt="image" src="https://github.com/user-attachments/assets/af4b7007-290e-400e-b851-1054d8cea40a" />|<img width="377" height="833" alt="image" src="https://github.com/user-attachments/assets/610e810e-cb79-4ff4-a180-32db8def4172" /> |

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

 child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.70,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: state.products.length,
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  return ProductCard(product: product);
                },
              ),
