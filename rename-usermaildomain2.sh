#!/bin/bash
find jobs -name config.xml > config_folder.txt
while read input; do
    name=$(echo "$input" | cut -d '|' -f 1 | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | tr '[:upper:]' '[:lower:]' )
    fullName=$(echo "$input" | cut -d '|' -f 2 | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//')
    email=$(echo "$input" | cut -d '|' -f 3 | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | tr '[:upper:]' '[:lower:]' )
    email_cutString=$(echo "$email" | cut -d '@' -f 1 | tr -d '.' | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//')
    uppercaseName="${name^^}"
    new_permission="<permission>USER:hudson.model.Hudson.Read:$email</permission>"


    ## Modify Users folder filename
    searchName="${name}_"
    fileName=$(ls users/ | grep -i "^$searchName")
    getNum="${fileName#*_}"
    if [ -d users/$fileName ] && [ "$fileName" != "" ]; then
        echo "Renaming $fileName to ${email_cutString}_${getNum}"
        cd users
       mv $fileName ${email_cutString}_${getNum}
        cd ..
echo "Modifying content of ${email_cutString}_${getNum}"
        if [ -f users/${email_cutString}_${getNum}/config.xml ]; then
            echo "Modifying content of ${email_cutString}_${getNum}"
            sed  -i "s/>$name/>$email/g" users/${email_cutString}_${getNum}/config.xml
            sed  -i "s/>$uppercaseName/>$email/g" users/${email_cutString}_${getNum}/config.xml

        fi
        if ! grep "<permission>" config.xml | grep -i $name ; then
            echo "adding permission block for $name"
            sed -i '0,/<\/permission>/s|<\/permission>|&\n    '"$new_permission"'|' config.xml
        fi
    else
           echo "ignoring user $name , not found in /users folder"
    fi


    ## modifying Jobs data

    while read folder; do
        if cat "$folder" | grep -i ":$uppercaseName<" > /dev/null ; then
            echo " $folder modification for user $uppercaseName"
            sed -i "s/$uppercaseName/$email/g" "$folder"
            sed -i "s/$name/$email/g" "$folder"
            sed -i "s/<permission>com/<permission>USER:com/g" "$folder"
        fi
    done < config_folder.txt

    ## modify users.xml folder
    sed -i "s/<string>$name/<string>$email/g" users/users.xml
    sed -i "s/<string>$fileName<\/string>/<string>${email_cutString}_${getNum}<\/string>/g" users/users.xml

    ## modify config.xml folder
    sed -i "s/:$name</:$email</g" config.xml
    sed -i "s/:$uppercaseName</:$email</g" config.xml

done < jenkins_user.txt
