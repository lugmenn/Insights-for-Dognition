-- ASSESSING IF THE DOGS' PERSONALITY HAVE EFFECT ON THE NUMBER OF TESTS COMPLETED

-- Explore the different categories dogs can be classified into by their personality (dimension)

SELECT DISTINCT dimension
FROM dogs;

-------------------------------------------------------------------------------------------------------------------------
-- Given that the query's output shows there are null values, further exploration into those cases is required.
-- For now, we can create a summary of the number of tests completed by each unique dog, alogside its personality.

SELECT DISTINCT 
    d.dog_guid AS dogID, 
    d.dimension AS dimension, 
    COUNT(c.created_at) AS tests_completed
FROM dogs d JOIN complete_tests c
    ON d.dog_guid=c.dog_guid
GROUP BY dogID
LIMIT 100;

-------------------------------------------------------------------------------------------------------------------------
-- After obtaining the number of tests completed by each individual dog, then the data can be aggregated to know how many 
-- tests were completed by dogs in a certain dimension or personality group.
-- The previous query will now be used as a subquery to create a temporary table to obtain the relevant data.

SELECT
   TestsPerDog.dimension AS personality, 
   AVG(TestsPerDog.tests_completed) AS AvgCompleteTests
FROM (SELECT DISTINCT 
        d.dog_guid AS dogID, 
        d.dimension AS dimension, 
        COUNT(c.created_at) AS tests_completed
      FROM dogs d JOIN complete_tests c
        ON d.dog_guid=c.dog_guid
      GROUP BY dogID
     ) AS TestsPerDog
GROUP BY personality;

-------------------------------------------------------------------------------------------------------------------------
-- The output returns 11 rows of dimension categories, which include a null-value category and a blank category (non-null or "").
-- To check out how many unique DogIDs are included in each of those categories, the following query can be used.

SELECT
    TestsPerDog.dimension AS personality, 
    COUNT(TestsPerDog.dogID) AS NumDogs
FROM (SELECT DISTINCT 
        d.dog_guid AS dogID, 
        d.dimension AS dimension, 
        COUNT(c.created_at) AS tests_completed
      FROM dogs d JOIN complete_tests c
        ON d.dog_guid=c.dog_guid
      WHERE dimension IS NULL OR dimension=""
      GROUP BY dogID
     ) AS TestsPerDog
GROUP BY personality;

-------------------------------------------------------------------------------------------------------------------------
-- The dogs with the null-value as dimension are those that did not completed the 20 required tests to be assigned a label.
-- The dogs with the blank category a dimension might indicate there were some odd conditions as to why they weren't assigned a label.
-- Now, let's find out if there are some common characteristics among those dogs.

SELECT DISTINCT 
    d.dog_guid AS dogID,
    d.breed, 
    d.weight, 
    d.dimension, 
    d.exclude,
    MIN(c.created_at) AS first_test, 
    MAX(c.created_at) AS last_test, 
    COUNT(c.created_at) AS completed_tests
FROM dogs d JOIN complete_tests c
    ON d.dog_guid=c.dog_guid
WHERE d.dimension=""
GROUP BY dogID;

-------------------------------------------------------------------------------------------------------------------------
-- The output shows most of the dogs with a blank dimension ("") have a exclude flag (value "1") in the exclude column.
-- DogIDs flagged with a 1 in that column are not meant to be included in the monitoring by the Dognition team.
-- Because of this, this might serve as an argument for excluding those entries with an empty non-null or blank dimension from the analysis.
-- The summary from step 3 should be redone, this time, excluding those dogs flagged with a 1 in the exclude column and a non-null empty value in the dimension field.
-- NOTE: the 'exclude' column might have a value or 1, 0 or a null-value. The Dognition team recognizes a null-value as a valid one,
-- so the query WHERE exclude!=1 will be appropiate because then, the output wouldn't include those null values.

SELECT
    TestsPerDog.dimension AS personality,
    AVG(TestsPerDog.tests_completed) AS AvgCompleteTests,
    COUNT(TestsPerDog.dogID) AS NumberOfDogs
FROM (SELECT DISTINCT 
        d.dog_guid AS dogID, 
        d.dimension AS dimension, 
        COUNT(c.created_at) AS tests_completed
      FROM dogs d JOIN complete_tests c
        ON d.dog_guid=c.dog_guid
      WHERE 
        (d.dimension IS NOT NULL AND d.dimension<>"") 
        AND 
        (d.exclude IS NULL OR d.exclude=0)
      GROUP BY dogID
     ) AS TestsPerDog
GROUP BY personality;

-- With a first glance, the results don't seem like there is a great effect of the dogs' personalities on the number of tests dogs can complete.
-- Eventhough a more profound statistical analysis could be done within these variables, it could be a better idea for the Dognition team to 
-- put their effort into analyzing different aspects to improve Dognition completion and usage rates.

-------------------------------------------------------------------------------------------------------------------------
-- -- ASSESSING IF BREEDS ARE RELATED TO THE NUMBER OF TESTS COMPLETED

-- First, we should find out how many breed groups are registered in the database

SELECT DISTINCT breed_group
FROM dogs;

-------------------------------------------------------------------------------------------------------------------------
-- The query's output shows there are null values among the breed group field, which should be further explored to find out those dogs characteristics.

SELECT DISTINCT 
     d.dog_guid AS dogID, 
     d.breed, 
     d.weight,
     d.exclude,
     MIN(c.created_at) AS first_test, 
     MAX(c.created_at) AS last_test, 
     COUNT(c.created_at) AS completed_tests
FROM dogs d JOIN complete_tests c
    ON d.dog_guid=c.dog_guid
WHERE d.breed_group IS NULL
GROUP BY dogID;

-------------------------------------------------------------------------------------------------------------------------
-- Since no pattern was found, no specific trait will be excluded from the analysis for now.
-- Next step will be to find out the relationship between breed group and the number of tests completed.

SELECT
    TestsPerDog.breed_group AS breed_group,
    COUNT(TestsPerDog.dogID) AS NumberOfDogs,
    SUM(TestsPerDog.tests_completed) AS TotalTests,
    AVG(TestsPerDog.tests_completed) AS AvgCompleteTests
FROM (SELECT DISTINCT 
        d.dog_guid AS dogID, 
        d.breed_group AS breed_group, 
        COUNT(c.created_at) AS tests_completed
      FROM dogs d JOIN complete_tests c
        ON d.dog_guid=c.dog_guid
      WHERE d.exclude IS NULL OR d.exclude=0
      GROUP BY dogID
     ) AS TestsPerDog
GROUP BY breed_group
ORDER BY AvgCompleteTests DESC;

-------------------------------------------------------------------------------------------------------------------------
-- Herding and Sporting groups turned out to have the highest number of completed tests.
-- Perhaps the Dognition team could deepen the analysis further specificaly into these breeds for creating marketing strategies or specific content for them.
-- To showcase the top 4 breed groups with the most number of completed tests for a report a valid query could be:

SELECT
    TestsPerDog.breed_group AS breed_group,
    COUNT(TestsPerDog.dogID) AS NumberOfDogs,
    SUM(TestsPerDog.tests_completed) AS TotalTests,
    AVG(TestsPerDog.tests_completed) AS AvgCompleteTests
FROM (SELECT DISTINCT 
        d.dog_guid AS dogID, 
        d.breed_group AS breed_group, 
        COUNT(c.created_at) AS tests_completed
      FROM dogs d JOIN complete_tests c
        ON d.dog_guid=c.dog_guid
      WHERE (d.exclude IS NULL OR d.exclude=0)
         AND
        d.breed_group IN ("Sporting","Hound","Herding","Working")
      GROUP BY dogID
     ) AS TestsPerDog
GROUP BY breed_group
ORDER BY AvgCompleteTests DESC;

-------------------------------------------------------------------------------------------------------------------------
-- Similarly to the queries for evaluating the different breed groups, now the breed types (breed purity) will be examined.

SELECT DISTINCT breed_type
FROM dogs;

-------------------------------------------------------------------------------------------------------------------------
-- Find the relationship between the breed type and the number of tests completed.

SELECT
    TestsPerDog.breed_type AS breed_type,
    COUNT(TestsPerDog.dogID) AS NumberOfDogs,
    SUM(TestsPerDog.tests_completed) AS TotalTests,
    AVG(TestsPerDog.tests_completed) AS AvgCompleteTests
FROM (SELECT DISTINCT 
        d.dog_guid AS dogID,
        d.breed_type AS breed_type,
        COUNT(c.created_at) AS tests_completed
      FROM dogs d JOIN complete_tests c
        ON d.dog_guid=c.dog_guid
      WHERE d.exclude IS NULL OR d.exclude=0
      GROUP BY dogID
     ) AS TestsPerDog
GROUP BY breed_type
ORDER BY AvgCompleteTests DESC;

-- There does not appear to be any appreciable difference between the number of tests and the dogs breed type.

-------------------------------------------------------------------------------------------------------------------------
-- -- ASSESSING IF BREED AND NEUTERING ARE RELATED TO THE NUMBER OF TESTS COMPLETED

-- Find the number of tests completed by pure breeds and not-pure breed dogs.

SELECT
    TestsPerDog.PureBreed AS PureBreed,
    COUNT(TestsPerDog.dogID) AS NumberOfDogs,
    SUM(TestsPerDog.NumberOfTests) AS TotalTests,
    AVG(TestsPerDog.NumberOfTests) AS AvgCompleteTests
FROM (SELECT DISTINCT 
        d.dog_guid AS dogID,
        COUNT(c.created_at) AS NumberOfTests,
        d.breed_type,
        CASE d.breed_type
            WHEN "Pure Breed" THEN "Pure_Breed"
            ELSE "Not_Pure_Breed"
            END AS PureBreed
      FROM dogs d JOIN complete_tests c
        ON d.dog_guid=c.dog_guid
      WHERE d.exclude IS NULL OR d.exclude=0
      GROUP BY dogID
     ) AS TestsPerDog
GROUP BY PureBreed
ORDER BY AvgCompleteTests DESC;

-------------------------------------------------------------------------------------------------------------------------
-- Find the the number of tests completed by breed type and whether or not the dogs were neutered.

SELECT
    TestsPerDog.PureBreed AS PureBreed,
    TestsPerDog.neutered AS Neutered,
    COUNT(TestsPerDog.dogID) AS NumberOfDogs,
    SUM(TestsPerDog.NumberOfTests) AS TotalTests,
    AVG(TestsPerDog.NumberOfTests) AS AvgCompleteTests
FROM (SELECT DISTINCT 
        d.dog_guid AS dogID,
        d.dog_fixed AS neutered,
        d.breed_type,
        CASE d.breed_type
            WHEN "Pure Breed" THEN "Pure_Breed"
            ELSE "Not_Pure_Breed"
            END AS PureBreed,
        COUNT(c.created_at) AS NumberOfTests
      FROM dogs d JOIN complete_tests c
        ON d.dog_guid=c.dog_guid
      WHERE d.exclude IS NULL OR d.exclude=0
      GROUP BY dogID
     ) AS TestsPerDog
GROUP BY PureBreed, Neutered;

-------------------------------------------------------------------------------------------------------------------------
-- Even though the breed type doesn't seem to have strong effects on the tests completed, neutered dogs seem to have completed, on average,
-- 1 or 2 more tests than non-neutered dogs. Further exploration of this condition could be fruitful in combination with other variables.
-- Find whether breed type could have effects on the time tests are completed.

SELECT 
    d.breed_type AS BreedType,
    AVG(TIMESTAMPDIFF(minute,e.start_time, e.end_time)) AS AvgDuration,
    STDDEV(TIMESTAMPDIFF(minute,e.start_time, e.end_time)) AS SDDuration
FROM dogs d JOIN exam_answers e
  ON d.dog_guid=e.dog_guid
WHERE
    TIMESTAMPDIFF(minute,e.start_time, e.end_time)>0
GROUP BY breed_type;

-- The large values in the standard deviation suggest the presence of extreme values in the completion of tests duration time. Because of this,
-- if this variable were to be used, a more complex statistical analysis, such as in R, would be necessary.