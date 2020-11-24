 

pragma solidity ^0.4.19;

 

contract Token{

  function doTransfer(address _from, address _to, uint256 _value) public returns (bool);

}

 

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 


contract VanityURL is Ownable,Pausable {

   
  Token public tokenAddress;
   
  mapping (string => address) vanity_address_mapping;
   
  mapping (address => string ) address_vanity_mapping;
   
  uint256 public reservePricing;
   
  address public transferTokenTo;

   
  function VanityURL(address _tokenAddress, uint256 _reservePricing, address _transferTokenTo){
    tokenAddress = Token(_tokenAddress);
    reservePricing = _reservePricing;
    transferTokenTo = _transferTokenTo;
  }

  event VanityReserved(address _to, string _vanity_url);
  event VanityTransfered(address _to,address _from, string _vanity_url);
  event VanityReleased(string _vanity_url);

   
  function updateTokenAddress (address _tokenAddress) onlyOwner public {
    tokenAddress = Token(_tokenAddress);
  }

   
  function updateTokenTransferAddress (address _transferTokenTo) onlyOwner public {
    transferTokenTo = _transferTokenTo;
  }

   
  function setReservePricing (uint256 _reservePricing) onlyOwner public {
    reservePricing = _reservePricing;
  }

   
  function retrieveWalletForVanity(string _vanity_url) constant public returns (address) {
    return vanity_address_mapping[_vanity_url];
  }

   
  function retrieveVanityForWallet(address _address) constant public returns (string) {
    return address_vanity_mapping[_address];
  }

   
  function reserve(string _vanity_url) whenNotPaused public {
    _vanity_url = _toLower(_vanity_url);
    require(checkForValidity(_vanity_url));
    require(vanity_address_mapping[_vanity_url]  == address(0x0));
    require(bytes(address_vanity_mapping[msg.sender]).length == 0);
    require(tokenAddress.doTransfer(msg.sender,transferTokenTo,reservePricing));
    vanity_address_mapping[_vanity_url] = msg.sender;
    address_vanity_mapping[msg.sender] = _vanity_url;
    VanityReserved(msg.sender, _vanity_url);
  }

   

  function _toLower(string str) internal returns (string) {
		bytes memory bStr = bytes(str);
		bytes memory bLower = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			 
			if ((bStr[i] >= 65) && (bStr[i] <= 90)) {
				 
				bLower[i] = bytes1(int(bStr[i]) + 32);
			} else {
				bLower[i] = bStr[i];
			}
		}
		return string(bLower);
	}

   
  function checkForValidity(string _vanity_url) returns (bool) {
    uint length =  bytes(_vanity_url).length;
    require(length >= 4 && length <= 200);
    for (uint i =0; i< length; i++){
      var c = bytes(_vanity_url)[i];
      if ((c < 48 ||  c > 122 || (c > 57 && c < 65) || (c > 90 && c < 97 )) && (c != 95))
        return false;
    }
    return true;
  }

   

  function changeVanityURL(string _vanity_url) whenNotPaused public {
    require(bytes(address_vanity_mapping[msg.sender]).length != 0);
    _vanity_url = _toLower(_vanity_url);
    require(checkForValidity(_vanity_url));
    require(vanity_address_mapping[_vanity_url]  == address(0x0));
    vanity_address_mapping[_vanity_url] = msg.sender;
    address_vanity_mapping[msg.sender] = _vanity_url;
    VanityReserved(msg.sender, _vanity_url);
  }

   
  function transferOwnershipForVanityURL(address _to) whenNotPaused public {
    require(bytes(address_vanity_mapping[_to]).length == 0);
    require(bytes(address_vanity_mapping[msg.sender]).length != 0);
    address_vanity_mapping[_to] = address_vanity_mapping[msg.sender];
    vanity_address_mapping[address_vanity_mapping[msg.sender]] = _to;
    VanityTransfered(msg.sender,_to,address_vanity_mapping[msg.sender]);
    delete(address_vanity_mapping[msg.sender]);
  }

   
  function reserveVanityURLByOwner(address _to,string _vanity_url) whenNotPaused onlyOwner public {
      _vanity_url = _toLower(_vanity_url);
      require(checkForValidity(_vanity_url));
       
      if(vanity_address_mapping[_vanity_url]  != address(0x0))
      {
         
        VanityTransfered(vanity_address_mapping[_vanity_url],_to,_vanity_url);
         
        delete(address_vanity_mapping[vanity_address_mapping[_vanity_url]]);
         
        delete(vanity_address_mapping[_vanity_url]);
      }
      else
      {
         
        VanityReserved(_to, _vanity_url);
      }
       
      vanity_address_mapping[_vanity_url] = _to;
      address_vanity_mapping[_to] = _vanity_url;
  }

   
  function releaseVanityUrl(string _vanity_url) whenNotPaused onlyOwner public {
    require(vanity_address_mapping[_vanity_url]  != address(0x0));
     
    delete(address_vanity_mapping[vanity_address_mapping[_vanity_url]]);
     
    delete(vanity_address_mapping[_vanity_url]);
     
    VanityReleased(_vanity_url);
  }

   

  function kill() onlyOwner {
    selfdestruct(owner);
  }

   
  function() payable {
    owner.transfer(msg.value);
  }

}