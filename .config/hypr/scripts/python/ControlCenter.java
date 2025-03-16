import javafx.application.Application;
import javafx.geometry.Insets;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.layout.*;
import javafx.stage.Stage;
import javafx.scene.image.ImageView;
import javafx.scene.control.Label;

public class ControlCenter extends Application {
    private StackPane contentArea;

    @Override
    public void start(Stage primaryStage) {
        primaryStage.setTitle("Control Center");
        
        // Main layout
        HBox mainBox = new HBox();
        
        // Sidebar
        VBox sidebar = new VBox(10);
        sidebar.setPrefWidth(200);
        sidebar.getStyleClass().add("sidebar");
        
        // Content area
        contentArea = new StackPane();
        contentArea.getStyleClass().add("content-page");
        
        // Add sidebar items
        String[][] categories = {
            {"System", "settings"},
            {"Display", "monitor"},
            {"Sound", "volume-up"},
            {"Network", "wifi"}
        };

        for (String[] category : categories) {
            Button button = createSidebarButton(category[0], category[1]);
            sidebar.getChildren().add(button);
        }

        mainBox.getChildren().addAll(sidebar, contentArea);
        
        Scene scene = new Scene(mainBox, 800, 600);
        scene.getStylesheets().add(getClass().getResource("style.css").toExternalForm());
        
        primaryStage.setScene(scene);
        primaryStage.show();
    }

    private Button createSidebarButton(String text, String iconName) {
        Button button = new Button(text);
        button.setMaxWidth(Double.MAX_VALUE);
        return button;
    }

    public static void main(String[] args) {
        launch(args);
    }
}
