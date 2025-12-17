Document Processing System

Student: Факи Доосууур Дорис 
Group: 11-200

This project demonstrates a document processing system using Yandex Cloud YDB, Message Queue, Cloud Functions, and Object Storage.

Overview

The system allows:

Uploading documents via an API endpoint.

Automatic processing and storage of documents in Object Storage.

Storing document metadata in YDB (Yandex Database).

Listing all uploaded documents through an API endpoint.


Проблемы и решение

Изначально попытки вставки данных через API YDB выдавали ошибку:

"Unsupported API version for table ..."


Отправка сообщений в Yandex Message Queue через CLI/curl также не работала.

Решение: использовать Cloud Functions, которые обрабатывают:

События очереди сообщений (загрузка документов)

HTTP-запросы через API Gateway (GET /documents)

Теперь загрузка автоматически запускает функцию, которая сохраняет файл в Storage и метаданные в YDB.
