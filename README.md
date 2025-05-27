Code for processing Micro doppler data for Radar classification.

How to Use:
To generate a dataset use generate_dataset.m:
  * change input/output directories to your file structure.
  * parentFolderPath should link to the folder "Dataset_848" which is given in the project.
  * num_elementsPerFeature defines the number of chunks a single data sample is split into 
    (all the files seem to be 10sec, so if num_elementsPerFeature=10, the processing is done for 1sec increments).

To change the feature set use extract_features.m:
  * code a new feature, for clarity please add it to a new section and number it (its sorta in WIP mode right now).
  * add it to the output struct
  * go to generate_feature_vectors and make sure the new feature is added to the output.
  * don't forget to commit changes to git. I copying and creating a new extract_features/generate_feature_vectors files if different feature sets are used.
