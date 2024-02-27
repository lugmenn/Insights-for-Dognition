-- ASSESSING WHICH WEEKDAY HAS THE HIGHEST ACTIVITY WITH THE MOST COMPLETED TESTS

-- Testing if there is a day in which the Dognition users complete are more likely to complete tests than on others.
-- First, create a query to obtain the date and day of the week in which each test is completed.

SELECT created_at, DAYOFWEEK(created_at)
FROM complete_tests
LIMIT 100;

-------------------------------------------------------------------------------------------------------------------------
-- Of course, it would be easier to understand if there was a column in which the name of the day, and not only the number, is also indicated.
-- For practicing, a CASE statement will be used to assign the day name instead of the DAYNAME() function.

SELECT
    created_at,
    CASE WHEN DAYOFWEEK(created_at)=1 THEN "Sunday"
        WHEN DAYOFWEEK(created_at)=2 THEN "Monday"
        WHEN DAYOFWEEK(created_at)=3 THEN "Tuesday"
        WHEN DAYOFWEEK(created_at)=4 THEN "Wednesday"
        WHEN DAYOFWEEK(created_at)=5 THEN "Thursday"
        WHEN DAYOFWEEK(created_at)=6 THEN "Friday"
        WHEN DAYOFWEEK(created_at)=7 THEN "Saturday"
    END AS Day_of_the_week,
    COUNT(created_at) AS number_TestsCompleted
FROM complete_tests
GROUP BY Day_of_the_week
ORDER BY number_TestsCompleted DESC;

-------------------------------------------------------------------------------------------------------------------------
-- So far, it seems as if more tests are completed during Sundays and fewer during Fridays.
-- Now, flagged dogs (with a value of 1 on the 'exclude' column) must be excluded from the analysis.

SELECT
    CASE WHEN DAYOFWEEK(c.created_at)=1 THEN "Sunday"
        WHEN DAYOFWEEK(c.created_at)=2 THEN "Monday"
        WHEN DAYOFWEEK(c.created_at)=3 THEN "Tuesday"
        WHEN DAYOFWEEK(c.created_at)=4 THEN "Wednesday"
        WHEN DAYOFWEEK(c.created_at)=5 THEN "Thursday"
        WHEN DAYOFWEEK(c.created_at)=6 THEN "Friday"
        WHEN DAYOFWEEK(c.created_at)=7 THEN "Saturday"
    END AS Day_of_the_week,
    COUNT(c.created_at) AS number_TestsCompleted
FROM complete_tests c JOIN dogs d
    ON c.dog_guid=d.dog_guid
WHERE d.exclude IS NULL OR d.exclude=0
GROUP BY Day_of_the_week
ORDER BY number_TestsCompleted DESC;

-------------------------------------------------------------------------------------------------------------------------
-- Next, follows the extraction of unique dogIDs common to the dogs and users tables (to avoid duplicates from both of those tables),
-- while also excluding flagged records.
-- This query shall be used as a subquery in the next step.

SELECT DISTINCT 
    dog_guid
FROM users u JOIN dogs d
  ON u.user_guid=d.user_guid
WHERE 
    (u.exclude IS NULL OR u.exclude=0) 
    AND (d.exclude IS NULL OR d.exclude=0);

-------------------------------------------------------------------------------------------------------------------------
-- The previous query will be used to adapt previous queries to find out how many tests were completed each day, now excluding duplicates and flagged records.

SELECT 
    DAYOFWEEK(c.created_at) AS DayNum,
    CASE WHEN DAYOFWEEK(c.created_at)=1 THEN "Sunday"
        WHEN DAYOFWEEK(c.created_at)=2 THEN "Monday"
        WHEN DAYOFWEEK(c.created_at)=3 THEN "Tuesday"
        WHEN DAYOFWEEK(c.created_at)=4 THEN "Wednesday"
        WHEN DAYOFWEEK(c.created_at)=5 THEN "Thursday"
        WHEN DAYOFWEEK(c.created_at)=6 THEN "Friday"
        WHEN DAYOFWEEK(c.created_at)=7 THEN "Saturday"
    END AS Day_of_the_week,
    COUNT(c.created_at) AS number_TestsCompleted
FROM complete_tests c JOIN
        (SELECT DISTINCT 
            dog_guid
        FROM users u JOIN dogs d
            ON u.user_guid=d.user_guid
        WHERE 
            ((u.exclude IS NULL OR u.exclude=0) 
            AND (d.exclude IS NULL OR d.exclude=0))
        ) AS dogs_cleaned
    ON c.dog_guid=dogs_cleaned.dog_guid
GROUP BY Day_of_the_week
ORDER BY number_TestsCompleted DESC;

-------------------------------------------------------------------------------------------------------------------------
-- The output still suggests more tests are completed during Sundays and less during Fridays.
-- New findings suggests more tests are completed during Thursdays than on Saturdays, in contrast with previous queries.
-- Since there's no access to another dataset, we can't be certain that this pattern is a well established phenomenon.
-- However, we can compare if this weekly completion rate is repeated across years within the available dataset.

SELECT 
    DAYOFWEEK(c.created_at) AS DayNum, 
    YEAR(c.created_at) AS Year,
    CASE WHEN DAYOFWEEK(c.created_at)=1 THEN "Sunday"
        WHEN DAYOFWEEK(c.created_at)=2 THEN "Monday"
        WHEN DAYOFWEEK(c.created_at)=3 THEN "Tuesday"
        WHEN DAYOFWEEK(c.created_at)=4 THEN "Wednesday"
        WHEN DAYOFWEEK(c.created_at)=5 THEN "Thursday"
        WHEN DAYOFWEEK(c.created_at)=6 THEN "Friday"
        WHEN DAYOFWEEK(c.created_at)=7 THEN "Saturday"
    END AS Day_of_the_week,
    COUNT(c.created_at) AS number_TestsCompleted
FROM complete_tests c JOIN
        (SELECT DISTINCT 
            dog_guid
        FROM users u JOIN dogs d
            ON u.user_guid=d.user_guid
        WHERE 
            ((u.exclude IS NULL OR u.exclude=0) 
            AND (d.exclude IS NULL OR d.exclude=0))
        ) AS dogs_cleaned
    ON c.dog_guid=dogs_cleaned.dog_guid
GROUP BY Year, Day_of_the_week
ORDER BY Year ASC, number_TestsCompleted DESC;

-------------------------------------------------------------------------------------------------------------------------
-- The weekly test completion pattern varies slightly across years, yet Sundays stays as the day with the most tests completed.
-- Because of this, the Dognition team could consider implementing an alert or notification system on Sundays.
-- The analysis, however, doesn't take into account all time stamps in the dataset are set the UTC, therefore a day variation in some of the tests might be possible.
-- Due to the lack of the proper data where the time zone for each record is indicated a precise result is not possible.
-- Fortunately, an approximate time stamp correction is possible to analyze customers in the US.
-- To analyze customer's weekly test completion living in the contigous USA, customers from Alaska and Hawaii were excluded in the next query.

SELECT 
    DAYOFWEEK(c.created_at) AS DayNum, 
    YEAR(c.created_at) AS Year,
    CASE WHEN DAYOFWEEK(c.created_at)=1 THEN "Sunday"
        WHEN DAYOFWEEK(c.created_at)=2 THEN "Monday"
        WHEN DAYOFWEEK(c.created_at)=3 THEN "Tuesday"
        WHEN DAYOFWEEK(c.created_at)=4 THEN "Wednesday"
        WHEN DAYOFWEEK(c.created_at)=5 THEN "Thursday"
        WHEN DAYOFWEEK(c.created_at)=6 THEN "Friday"
        WHEN DAYOFWEEK(c.created_at)=7 THEN "Saturday"
    END AS Day_of_the_week,
    COUNT(c.created_at) AS number_TestsCompleted
FROM complete_tests c JOIN
        (SELECT DISTINCT dog_guid
        FROM users u JOIN dogs d
            ON u.user_guid=d.user_guid
        WHERE 
            ((u.country="US") 
            AND (state!="HI" AND state!="AK")
            AND (u.exclude IS NULL OR u.exclude=0) 
            AND (d.exclude IS NULL OR d.exclude=0))
        ) AS dogs_cleaned
    ON c.dog_guid=dogs_cleaned.dog_guid
GROUP BY Year, Day_of_the_week
ORDER BY Year ASC, number_TestsCompleted DESC;

-------------------------------------------------------------------------------------------------------------------------
-- Next, the for the time stamp correction, created_at was adjusted to a time zone of UTC -8 to -5 hours.
-- The goal is to get a general idea or a glimpse of customers' usage in mainland USA, thus, a median value of time correction of -6 hours is the chosen option.
-- A more precise analysis could be done in each timezone with its corresponding states.
-- This query serves to check out the proper syntax, which is meant to be incorporated into the previous query.

SELECT 
    created_at, 
    DATE_SUB(created_at, INTERVAL 6 HOUR) AS "US_time(-6 hours)"
FROM complete_tests
LIMIT 100;


SELECT 
    DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR)) AS DayNum, 
    YEAR(c.created_at) AS Year,
    CASE WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=1 THEN "Sun"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=2 THEN "Mon"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=3 THEN "Tue"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=4 THEN "Wed"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=5 THEN "Thu"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=6 THEN "Fri"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=7 THEN "Sat"
    END AS Day_of_the_week,
    COUNT(c.created_at) AS number_TestsCompleted
FROM complete_tests c JOIN
        (SELECT DISTINCT 
            dog_guid
        FROM users u JOIN dogs d
            ON u.user_guid=d.user_guid
        WHERE ((u.country="US") 
            AND (state!="HI" AND state!="AK")
            AND (u.exclude IS NULL OR u.exclude=0) 
            AND (d.exclude IS NULL OR d.exclude=0))
        ) AS dogs_cleaned
    ON c.dog_guid=dogs_cleaned.dog_guid
GROUP BY Year, Day_of_the_week
ORDER BY Year ASC, number_TestsCompleted DESC;

-------------------------------------------------------------------------------------------------------------------------
-- For a better understanding of the weekly test completion the days arrangement is modified, from Monday to Sunday.

SELECT 
    DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR)) AS DayNum, 
    YEAR(c.created_at) AS Year,
    CASE 
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=1 THEN "Sun"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=2 THEN "Mon"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=3 THEN "Tue"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=4 THEN "Wed"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=5 THEN "Thu"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=6 THEN "Fri"
        WHEN DAYOFWEEK(DATE_SUB(c.created_at, INTERVAL 6 HOUR))=7 THEN "Sat"
    END AS Day_of_the_week,
    COUNT(c.created_at) AS number_TestsCompleted
FROM complete_tests c JOIN
        (SELECT DISTINCT 
            dog_guid
        FROM users u JOIN dogs d
            ON u.user_guid=d.user_guid
        WHERE ((u.country="US") 
            AND (state!="HI" AND state!="AK")
            AND (u.exclude IS NULL OR u.exclude=0) 
            AND (d.exclude IS NULL OR d.exclude=0))
        ) AS dogs_cleaned
    ON c.dog_guid=dogs_cleaned.dog_guid
GROUP BY Year, Day_of_the_week
ORDER BY Year ASC, FIELD(Day_of_the_week, "Mon","Tue", "Wed", "Thu", "Fri", "Sat", "Sun");

-------------------------------------------------------------------------------------------------------------------------
-- ASSESSING WHICH STATES AND COUNTRIES HAVE THE HIGHEST NUMBER OF USERS

-- Finding out the top 5 USA states with Dognition customers (excluding flagged users and dogs)

SELECT
    dogs_cleaned.state AS State, 
    COUNT(dogs_cleaned.user_guid) AS Number_Users
FROM complete_tests c JOIN
        (SELECT DISTINCT 
            d.dog_guid, 
            u.user_guid, 
            u.state
        FROM dogs d JOIN users u
            ON u.user_guid=d.user_guid
        WHERE ((u.country="US") 
            AND (u.exclude IS NULL OR u.exclude=0) 
            AND (d.exclude IS NULL OR d.exclude=0))
        ) AS dogs_cleaned
    ON c.dog_guid=dogs_cleaned.dog_guid
GROUP BY State
ORDER BY Number_Users DESC
LIMIT 5;

-------------------------------------------------------------------------------------------------------------------------
-- California is the state with the most Dognition users, being more than two times greater than any other state.
-- To evaluate why, it is a good idea to check out if there were any special promotions run in California, particular succesful marketing strategies in that state 
-- or how are the customers there different to customers from other states.

-- Find out which are the countries with the highest number of users

SELECT
    dogs_cleaned.country AS Country, 
    COUNT(dogs_cleaned.user_guid) AS Number_Users
FROM complete_tests c JOIN
        (SELECT DISTINCT 
            d.dog_guid, 
            u.user_guid, 
            u.country
        FROM dogs d JOIN users u
            ON u.user_guid=d.user_guid
        WHERE 
            ((u.exclude IS NULL OR u.exclude=0) 
            AND (d.exclude IS NULL OR d.exclude=0))
        ) AS dogs_cleaned
    ON c.dog_guid=dogs_cleaned.dog_guid
GROUP BY Country
ORDER BY Number_Users DESC
LIMIT 5;

-- The countries where most Dognition users are located are Englishs speaking countries, such as USA, Canada, the UK, and Australia.
-- As a suggestion the Dognition team could find out if a translation of the website cound be a good strategy to expand and increase customers in from other countries.