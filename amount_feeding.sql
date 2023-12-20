CREATE TABLE amount_food (
	id serial PRIMARY KEY,
	"date" Date NOT NULL DEFAULT CURRENT_DATE,
	"time" time NOT NULL DEFAULT CURRENT_TIME(0),
	category text NOT NULL,
	amount numeric NOT NULL
);

INSERT INTO amount_food (date, time, category, amount) VALUES
('2023-09-09', '15:00:00', 'dry', 7.8),
('2023-10-09', '15:00:00', 'dry', 9.7),
('2023-11-09', '15:00:00', 'dry', 7.8);