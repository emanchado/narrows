import express from "express";

var app = express();

app.use(express.static('public'));

app.get("/api/fragments/:fragmentId/:characterId", function(req, res) {
    res.json({
        title: "The Tavern",
        audio: "/media/Mountain_Tavern.mp3",
        backgroundImage: "/img/tavern.jpg",
        text: {
            "type": "doc",
            "content": [
                {
                    "type": "paragraph",
                    "content": [
                        {
                            "type": "text",
                            "text": "This is a"
                        }
                    ]
                },
                {
                    "type": "paragraph",
                    "content": [
                        {
                            "type": "image",
                            "attrs": {
                                "src": "images/hoek.png",
                                "alt": "",
                                "title": ""
                            },
                            "marks": [
                                {
                                    "_": "mention",
                                    "mentionTarget": "Atana"
                                }
                            ]
                        }
                    ]
                },
                {
                    "type": "bullet_list",
                    "content": [
                        {
                            "type": "list_item",
                            "content": [
                                {
                                    "type": "paragraph",
                                    "content": [
                                        {
                                            "type": "text",
                                            "text": "Item 1"
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            "type": "list_item",
                            "content": [
                                {
                                    "type": "paragraph",
                                    "content": [
                                        {
                                            "type": "text",
                                            "text": "Item 2"
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                },
                {
                    "type": "paragraph",
                    "content": [
                        {
                            "type": "text",
                            "text": "And something at the end"
                        }
                    ]
                }
            ]
        }
    });
});

app.post("/api/reactions/:fragmentId/:characterId", function(req, res) {
    res.send("Saving reaction");
});

app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
});
