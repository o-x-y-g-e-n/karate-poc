package application.cart;

import java.util.List;
import java.util.Map;

import framework.Assertions;

public class CartUtils {

    /**
     * *********************************
     * ********* ASSERTIONS ************
     * *********************************
     */
    public static void validateCarts(List<Map<String, Object>> carts) {
        for (Map<String, Object> cart : carts) {
            double sumOfAllDiscounted = 0;
            double sumOfTotal = 0;
            List<Map<String, Object>> products = (List<Map<String, Object>>) cart.get("products");
            for (Map<String, Object> product : products) {
                double discountedPrice = ((Number) product.getOrDefault("discountedPrice", 0)).intValue();
                double productTotal = ((Number) product.getOrDefault("total", 0)).intValue();
                double productDiscountPercentage = ((Number) product.getOrDefault("discountPercentage", 0)).doubleValue();
                double productDiscountTotal = ((Number) product.getOrDefault("discountedPrice", 0)).intValue();
                double productPrice = ((Number) product.getOrDefault("price", 0)).intValue();
                int quantity = ((Number) product.getOrDefault("quantity", 0)).intValue();
                double calculatedDiscountedPrice = productTotal - (productTotal * (productDiscountPercentage / 100));
                sumOfAllDiscounted += discountedPrice;
                sumOfTotal += productTotal;

                Assertions.assertEquals(productPrice * quantity, productTotal);
                Assertions.assertEquals((int) Math.round(calculatedDiscountedPrice), (int) Math.round(productDiscountTotal));
            }

            Assertions.assertEquals(products.size(), cart.get("totalProducts"));
            Assertions.assertEquals((int) Math.round(sumOfTotal), cart.get("total"));
            Assertions.assertEquals((int) sumOfAllDiscounted, cart.get("discountedTotal"));
        }
    }

    public static void validateProductDetails(List<Map<String, Object>> products, Object productsfromAPIs) {
        for (int i = 0; i < products.size(); i++) {
            Assertions.assertEquals(products.size(), ((List<Map<String, Object>>) productsfromAPIs).size());
            Map<String, Object> productFromCart = products.get(i);
            Map<String, Object> productFromAPI = ((List<Map<String, Object>>) productsfromAPIs).get(i);
            Assertions.assertEquals(productFromCart.get("title"), productFromAPI.get("title"));
            Assertions.assertEquals(productFromCart.get("price"), productFromAPI.get("price"));
        }
        ;
    }
}
