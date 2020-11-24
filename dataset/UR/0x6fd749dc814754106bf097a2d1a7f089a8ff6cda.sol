 

pragma solidity ^0.4.24;

 

library NameFilter {

     
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

         
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
         
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

         
        bool _hasNonNumber;

         
        for (uint256 i = 0; i < _length; i++)
        {
             
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                 
                _temp[i] = byte(uint(_temp[i]) + 32);

                 
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                     
                    _temp[i] == 0x20 ||
                     
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                     
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                 
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                 
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

interface PlayerBookReceiverInterface {
    function receivePlayerInfo(address _addr, string _name) external;
}

contract PlayerBook is Ownable {
    using NameFilter for string;
    
    string constant public name = "PlayerBook";
    string constant public symbol = "PlayerBook";    

    uint256 public registrationFee_ = 10 finney;             
    mapping (bytes32 => address) public nameToAddr;
    mapping (address => string[]) public addrToNames;
    
    PlayerBookReceiverInterface public currentGame; 
    
    address public CFO;
    address public COO; 
    
    modifier onlyCOO() {
        require(msg.sender == COO);
        _; 
    }
    
    constructor(address _CFO, address _COO) public {
        CFO = _CFO;
        COO = _COO; 
    }
    
    function setCFO(address _CFO) onlyOwner public {
        CFO = _CFO; 
    }  
  
    function setCOO(address _COO) onlyOwner public {
        COO = _COO; 
    }  

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    

    function checkIfNameValid(string _nameStr) public view returns(bool) {
      bytes32 _name = _nameStr.nameFilter();
      if (nameToAddr[_name] == address(0))
        return (true);
      else
        return (false);
    }

    function getPlayerAddr(string _nameStr) public view returns(address) {
      bytes32 _name = _nameStr.nameFilter();
      return nameToAddr[_name];
    }

    function getPlayerName() public view returns(string) {
      address _addr = msg.sender;
      string[] memory names = addrToNames[_addr];
      if(names.length > 0) {
        return names[names.length-1];
      } else {
        return ""; 
      }
    }

    function registerName(string _nameString) public isHuman payable {
       
      require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");

       
      bytes32 _name = NameFilter.nameFilter(_nameString);
      require(nameToAddr[_name] == address(0), "name must not be taken by others");
      address _addr = msg.sender;
      nameToAddr[_name] = _addr;
      addrToNames[_addr].push(_nameString);
       
      currentGame.receivePlayerInfo(_addr, _nameString); 
    }

    function registerNameByCOO(string _nameString, address _addr) public onlyCOO {
      bytes32 _name = NameFilter.nameFilter(_nameString);
      require(nameToAddr[_name] == address(0), "name must not be taken by others");
      nameToAddr[_name] = _addr;
      addrToNames[_addr].push(_nameString);
       
      currentGame.receivePlayerInfo(_addr, _nameString);       
    }
    
    
    function setCurrentGame(address _addr) public onlyCOO {
        currentGame = PlayerBookReceiverInterface(_addr); 
    }

    function withdrawBalance() public onlyCOO {
      uint _amount = address(this).balance;
      CFO.transfer(_amount);
    }
}