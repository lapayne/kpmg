function getObject($key, $searchObject){
    #searchs through every object in the current array
    foreach($obj in $searchObject){
        #if the key is present in the current object then return the value
        if($obj -contains $key){
            return $obj.value
        }
        #othersie submit the new subject to the same function 
        else{
            getObject($key, $obj)
        }
    }
}