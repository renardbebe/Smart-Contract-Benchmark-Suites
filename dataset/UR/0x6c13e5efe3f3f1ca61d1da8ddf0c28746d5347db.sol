 

pragma solidity ^0.4.2;


contract DataPost{

    function () {
         
        throw;
    }
    event dataPosted(
    	address poster,
    	string data,
    	string hash_algorithm,
    	string signature,
    	string signature_spec
    );
  	function postData(string data, string hash_algorithm,string signature,string signature_spec){
  		emit dataPosted(msg.sender,data,hash_algorithm,signature,signature_spec);
  	}
   
}