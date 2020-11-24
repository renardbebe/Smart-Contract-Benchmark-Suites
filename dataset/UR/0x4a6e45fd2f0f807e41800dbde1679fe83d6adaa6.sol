 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 


 
contract Owned {

   address public owner;
   address public proposedOwner;

   event OwnershipTransferInitiated(address indexed _proposedOwner);
   event OwnershipTransferCompleted(address indexed _newOwner);


   function Owned() public
   {
      owner = msg.sender;
   }


   modifier onlyOwner() {
      require(isOwner(msg.sender) == true);
      _;
   }


   function isOwner(address _address) public view returns (bool) {
      return (_address == owner);
   }


   function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
      require(_proposedOwner != address(0));
      require(_proposedOwner != address(this));
      require(_proposedOwner != owner);

      proposedOwner = _proposedOwner;

      OwnershipTransferInitiated(proposedOwner);

      return true;
   }


   function completeOwnershipTransfer() public returns (bool) {
      require(msg.sender == proposedOwner);

      owner = msg.sender;
      proposedOwner = address(0);

      OwnershipTransferCompleted(owner);

      return true;
   }
}

 
 
 
 
 
 
 


library Math {

   function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 r = a + b;

      require(r >= a);

      return r;
   }


   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(a >= b);

      return a - b;
   }


   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
         return 0;
      }

      uint256 r = a * b;

      require(r / a == b);

      return r;
   }


   function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
   }
}

 
 
 
 
 
 
 

 
 
 
 
contract ERC20Interface {

   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   function name() public view returns (string);
   function symbol() public view returns (string);
   function decimals() public view returns (uint8);
   function totalSupply() public view returns (uint256);

   function balanceOf(address _owner) public view returns (uint256 balance);
   function allowance(address _owner, address _spender) public view returns (uint256 remaining);

   function transfer(address _to, uint256 _value) public returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
   function approve(address _spender, uint256 _value) public returns (bool success);
}

 
 
 
 
 
 
 


contract ERC20Batch is Owned {

   using Math for uint256;

   ERC20Interface public token;
   address public tokenHolder;


   event TransferFromBatchCompleted(uint256 _batchSize);


   function ERC20Batch(address _token, address _tokenHolder) public
      Owned()
   {
      require(_token != address(0));
      require(_tokenHolder != address(0));

      token = ERC20Interface(_token);
      tokenHolder = _tokenHolder;
   }


   function transferFromBatch(address[] _toArray, uint256[] _valueArray) public onlyOwner returns (bool success) {
      require(_toArray.length == _valueArray.length);
      require(_toArray.length > 0);

      for (uint256 i = 0; i < _toArray.length; i++) {
         require(token.transferFrom(tokenHolder, _toArray[i], _valueArray[i]));
      }

      TransferFromBatchCompleted(_toArray.length);

      return true;
   }
}