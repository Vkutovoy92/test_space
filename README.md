Сборка и запуск - make run 

Очистка проекта - make clean

Запросы 

GET - получить новость по id

http://localhost:8080/api/36 (36 - ид новости)

Ответ успех
```
{
    "body": "{\"html\":{\"head\":{\"title\":
    {\"#text\":\"\"}},\"body\":{\"p\":[{\"#text\":\"BLA BLA\"},
    {\"#text\":\"It only has two p2aragraphs1\"}]}}}",
    "result": "success"
}
```
Ответ ошибка (одна из)
```
{
    "reason": "not body for this id",
    "result": "error"
}
```



================================================


POST - сохранить новость и получить её id

http://localhost:8080/api

Запрос
```
<html>
<head>
<title>
</title>
</head>
<body>
<p>selec12t</p>
<p>It only has two p2aragraphs1</p>
</body>
</html>
```

Ответ успех
```
{
    "id": 41,
    "result": "success"
}
```
Ответ ошибка (одна из)
```
{
    "reason": "news already exists",
    "result": "error"
}
```

================================================


DELETE - удалить новость по id

Тело можно не передавать

http://localhost:8080/api/36 (36 - ид новости)

Ответ успех
```
{
    "result": "success"
}
```
Ответ ошибка (одна из)
```
{
    "reason": "not body for this id ib db",
    "result": "error"
}
```
================================================

PUT - обновить новость по id

http://localhost:8080/api/41 (41 - ид новости)

Тело запроса
```
<html>
<head>
<title>
</title>
</head>
<body>
<p>dsadasdasd</p>
<p>asdasdasdas</p>
</body>
</html>
```
Ответ успех
```
{
    "result": "success"
}
```

Ответ ошибка (одна из)
```
{
    "reason": "id not found",
    "result": "error"
}
```
