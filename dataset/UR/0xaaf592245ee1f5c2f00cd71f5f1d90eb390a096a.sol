 

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;







contract SuperplayerCharacter is Ownable {
  using SafeMath for uint256;


  event CharacterSelect(address from ,uint32 chaId) ;
  mapping(address => uint32) public addrMapCharacterIds;
  uint256 changeFee = 0;


  struct Character {
    uint32 id ;
    uint weight ;
  }


  Character[] private characters;
  uint256 totalNum = 0;
  uint256 totalWeight = 0;

  constructor() public {
      _addCharacter(1,1000000);
      _addCharacter(2,1000000);
      _addCharacter(3,1000000);
      _addCharacter(4,1000);
      _addCharacter(5,1000);
      _addCharacter(6,1000);
  }


  function AddCharacter(uint32 id ,uint weight ) public onlyOwner{
    _addCharacter(id,weight);
  }


  function SetFee( uint256 fee ) public onlyOwner {
    changeFee = fee;
  }




  function withdraw( address payable to )  public onlyOwner{
    require(to == msg.sender);  
    to.transfer((address(this).balance ));
  }

  function getConfig() public view returns(uint32[] memory ids,uint256[] memory weights){
     ids = new uint32[](characters.length);
     weights = new uint[](characters.length);
     for (uint i = 0;i < characters.length ; i++){
          Character memory ch  = characters[i];
          ids[i] = ch.id;
          weights[i] = ch.weight;
     }
  }

  function () payable external{
    require(msg.value >= changeFee);
    uint sum = 0 ;
    uint index = characters.length - 1;

    uint weight = uint256(keccak256(abi.encodePacked(block.timestamp,msg.value,block.difficulty))) %totalWeight + 1;

    for (uint i = 0;i < characters.length ; i++){
      Character memory ch  = characters[i];
      sum += ch.weight;
      if( weight  <=  sum ){
        index = i;
        break;
      }
    }
    _selectCharacter(msg.sender,characters[index].id);

    msg.sender.transfer(msg.value.sub(changeFee));
  }

  function _selectCharacter(address from,uint32 id) internal{
    addrMapCharacterIds[from] = id;
    emit CharacterSelect(from,id);
  }



  function  _addCharacter(uint32 id ,uint weight) internal  {
    Character memory char = Character({
      id : id,
      weight :weight
    });
    characters.push(char);
    totalNum = totalNum.add(1);
    totalWeight  = totalWeight.add(weight);
  }

}