import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.clickable

@androidx.compose.runtime.Composable
fun HomeScreen(navController: androidx.navigation.NavController) {
    val imageUrls = listOf(
        "https://example.com/image1.jpg",
        "https://example.com/image2.jpg",
        // ... tambahkan URL gambar lainnya di sini
    )

    androidx.compose.foundation.lazy.LazyColumn {
        items(imageUrls) { imageUrl ->
            ImageCard(imageUrl) {
                navController.navigate("detail/$imageUrl")
            }
        }
    }
}

@androidx.compose.runtime.Composable
fun ImageCard(imageUrl: String, onClick: () -> Unit) {
    androidx.compose.material3.Card(
        modifier = androidx.compose.ui.Modifier
            .fillMaxWidth()
            .padding(8.dp)
            .clickable { onClick() },
        elevation = 4.dp
    ) {
        AsyncImage(
            model = imageUrl,
            contentDescription = "Gambar",
            modifier = androidx.compose.ui.Modifier.fillMaxWidth()
        )
    }
}