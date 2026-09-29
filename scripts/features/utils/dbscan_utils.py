import time
from sklearn.neighbors import NearestNeighbors
from sklearn.cluster import DBSCAN
import matplotlib.pyplot as plt
from sklearn.metrics import silhouette_score, davies_bouldin_score
import pandas as pd
import numpy as np


# suggest_eps_range : détermine une suite de min_samples 
# Courbe k-distance 

def suggest_eps_range(X, k=4, n_points=30):
    neighbors = NearestNeighbors(n_neighbors=k).fit(X)
    distances, _ = neighbors.kneighbors(X)
    k_distances = np.sort(distances[:, k - 1])

    plt.figure(figsize=(6, 4))
    plt.plot(k_distances)
    plt.ylabel(f"Distance au {k}-ieme voisin")
    plt.xlabel("Points tries par distance croissante")
    plt.title("Courbe k-distance (cherchez le coude)")
    plt.tight_layout()
    plt.savefig("k_distance_curve.png", dpi=120)
    plt.close()

    low, high = np.percentile(k_distances, [70, 95])
    low = max(low, 1.0)
    if high <= low:
        high = low + 1000.0
    return np.linspace(low, high, n_points)


# dbscan_grid_search : utilise l'algorithme DBSCAN
#  pour déterminer les meilleures valeurs de eps et min_samples
#  en utilisant les métriques silhouette_score et davies_bouldin_score

def dbscan_grid_search(X, eps_values, min_samples_values, silhouette_sample_size=100000):
    results = []

    for min_samples in min_samples_values:
        for eps in eps_values:
            labels = DBSCAN(eps=eps, min_samples=min_samples, algorithm="kd_tree").fit_predict(X)

            n_clusters = len(set(labels)) - (1 if -1 in labels else 0)
            noise_ratio = np.mean(labels == -1)

            mask = labels != -1
            if n_clusters >= 2 and mask.sum() > n_clusters:
                n_valid = mask.sum()
                sample = min(silhouette_sample_size, n_valid) if n_valid > silhouette_sample_size else None
                sil = silhouette_score(X[mask], labels[mask], sample_size=sample, random_state=42)
                dbi = davies_bouldin_score(X[mask], labels[mask])
            else:
                sil, dbi = np.nan, np.nan

            results.append({
                "eps": round(eps, 4),
                "min_samples": min_samples,
                "n_clusters": n_clusters,
                "noise_ratio": round(noise_ratio, 3),
                "silhouette": sil,
                "davies_bouldin": dbi,
            })

    return pd.DataFrame(results)


# select_best_params : formate les résultats du grid search 
def select_best_params(df, max_noise_ratio=0.35, min_clusters=6):
    candidates = df[
        (df["noise_ratio"] <= max_noise_ratio)
        & (df["n_clusters"] >= min_clusters)
        & (df["silhouette"].notna())
    ].copy()

    if candidates.empty:
        print("Aucune combinaison satisfaisante : "
              "elargissez max_noise_ratio ou la plage eps/min_samples.")
        return None

    # Score combine simple : on privilegie silhouette haut et DBI bas
    candidates["combined_score"] = (
        candidates["silhouette"] - candidates["davies_bouldin"]
    )
    candidates = candidates.sort_values("combined_score", ascending=False)
    return candidates


# plot_clusters : scatter plot des clusters

def plot_clusters(X, labels, title="Clusters DBSCAN", figsize=(9, 9), point_size=15):
    unique_labels = sorted(set(labels))
    n_clusters = len(unique_labels) - (1 if -1 in unique_labels else 0)

    fig, ax = plt.subplots(figsize=figsize)

    cmap = plt.get_cmap("tab20", max(n_clusters, 1))
    color_idx = 0

    for lbl in unique_labels:
        mask = labels == lbl
        if lbl == -1:
            ax.scatter(
                X[mask, 0], X[mask, 1],
                c="lightgray", s=point_size, label=f"Bruit (n={mask.sum()})",
                alpha=0.6, edgecolors="none"
            )
        else:
            ax.scatter(
                X[mask, 0], X[mask, 1],
                c=[cmap(color_idx)], s=point_size, label=f"Cluster {lbl} (n={mask.sum()})",
                alpha=0.85, edgecolors="none"
            )
            color_idx += 1

    ax.set_xlabel("x (m)")
    ax.set_ylabel("y (m)")
    ax.set_title(f"{title} — {n_clusters} clusters")
    ax.set_aspect("equal")
    ax.legend(loc="center left", bbox_to_anchor=(1.0, 0.5), fontsize=8, markerscale=1.5)
    plt.tight_layout()
    plt.savefig("clusters_scatter.png", dpi=150, bbox_inches="tight")
    plt.show()

    return fig, ax


def db_scan(df, region, eps, min_samples):

    df_region = df.groupby("region").get_group(region).copy()
    X = df_region[["x", "y"]].values
    
    labels = DBSCAN(eps=eps, min_samples=min_samples)

    # fit_predict(X) fait deux choses d’un coup : il apprend les clusters sur X, 
    #  puis renvoie un tableau d’entiers, une valeur par ligne, dans le même ordre que df.
    #  Dès qu’il trouve un nouveau groupe dense, il lui donne le prochain entier : 0, puis 1, puis 2
    #  Il peut renvoyer -1 : point trop isolé
    clusters_locaux = labels.fit_predict(X)
    
    # ajustement des clusters locaux (-1 devient 0, les autres +1)
    df_region["cluster_local"] = np.where(
        clusters_locaux == -1, 0, clusters_locaux + 1
    )

    # Création du cluster global (ex: "17_1", "17_2")
    df_region["cluster_id"] = (
        df_region["region"].astype(str) + "_" + df_region["cluster_local"].astype(str)
    )
    
    return df_region