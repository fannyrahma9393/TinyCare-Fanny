<?php

return [

    'paths' => ['*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        'https://tinycare.my.id',
        'http://tinycare.my.id',
        'http://localhost:5173',
        'http://localhost:3000',
        'http://localhost:8000',
    ],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,

];
