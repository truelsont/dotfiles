#include <QApplication>
#include <QLabel>
#include <QMainWindow>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QMainWindow window;
    window.setWindowTitle("Hello Qt");

    QLabel *label = new QLabel("Hello, World!", &window);
    label->setAlignment(Qt::AlignCenter);
    window.setCentralWidget(label);

    window.resize(400, 300);
    window.show();

    return app.exec();
}
