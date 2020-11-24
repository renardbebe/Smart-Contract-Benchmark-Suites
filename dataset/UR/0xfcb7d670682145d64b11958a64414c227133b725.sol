 

pragma solidity ^0.4.24;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 

 
 
 
 
contract allowanceRecipient {
    function receiveApproval(address _from, uint256 _value, address _inContract, bytes _extraData) public returns (bool);
}


 
 
contract tokenRecipient {
    function tokenFallback(address _from, uint256 _value, bytes _extraData) public returns (bool);
}

 
contract ACCP {

     
    using SafeMath for uint256;

    address public owner;

     

     
     
    string public name = "ACCP";

     
     
    string public symbol = "ACCP";

     
     
    uint8 public decimals = 0;

     
     
     
    uint256 public totalSupply = 10 * 1000000000;  

     
     
    mapping(address => uint256) public balanceOf;

     
     
    mapping(address => mapping(address => uint256)) public allowance;

     

     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed spender, uint256 value);

     
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes _extraData);

     
    bool public transfersBlocked = false;
    mapping(address => bool) public whiteListed;

     
     
     
    constructor() public {
         
        owner = 0xff809E4ebB5F94171881b3CA9a0EBf4405C6370a;
         
        balanceOf[this] = totalSupply;
    }

    event TransfersBlocked(address indexed by); 
    function blockTransfers() public { 
         
        require(msg.sender == owner);
         
        require(!transfersBlocked);
        transfersBlocked = true;
        emit TransfersBlocked(msg.sender);
    }

    event TransfersAllowed(address indexed by); 
    function allowTransfers() public { 
         
        require(msg.sender == owner);
         
        require(transfersBlocked);
        transfersBlocked = false;
        emit TransfersAllowed(msg.sender);
    }

    event AddedToWhiteList(address indexed by, address indexed added); 
    function addToWhiteList(address acc) public { 
         
        require(msg.sender == owner);
         
        whiteListed[acc] = true;
        emit AddedToWhiteList(msg.sender, acc);
    }

    event RemovedFromWhiteList(address indexed by, address indexed removed); 
    function removeFromWhiteList(address acc) public { 
         
        require(msg.sender == owner);
         
        require(acc != owner);
         
        whiteListed[acc] = false;
        emit RemovedFromWhiteList(msg.sender, acc);
    }

    event tokensBurnt(address indexed by, uint256 value);  
    function burnTokens() public { 
         
        require(msg.sender == owner);
         
        require(balanceOf[this] > 0);
        emit tokensBurnt(msg.sender, balanceOf[this]);
        balanceOf[this] = 0;
    }

     
     

     
    function transfer(address _to, uint256 _value) public returns (bool){
        return transferFrom(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

         
        require(_value >= 0);

         
        require(msg.sender == _from || _value <= allowance[_from][msg.sender] || (_from == address(this) && msg.sender == owner));

         
        require(!transfersBlocked || (whiteListed[_from] && whiteListed[msg.sender]));

         
        require(_value <= balanceOf[_from]);

         
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
         
         
        balanceOf[_to] = balanceOf[_to].add(_value);

         
        if (_from != msg.sender && (!(_from == address(this) && msg.sender == owner))) {
             
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

         
        emit Transfer(_from, _to, _value);

        return true;
    }  

     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool){
        require(_value >= 0);
        allowance[msg.sender][_spender] = _value;
         
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {

        approve(_spender, _value);

         
        allowanceRecipient spender = allowanceRecipient(_spender);

         
         
         
        if (spender.receiveApproval(msg.sender, _value, this, _extraData)) {
            emit DataSentToAnotherContract(msg.sender, _spender, _extraData);
            return true;
        }
        return false;
    }  

     
    function approveAllAndCall(address _spender, bytes _extraData) public returns (bool success) {
        return approveAndCall(_spender, balanceOf[msg.sender], _extraData);
    }

     
    function transferAndCall(address _to, uint256 _value, bytes _extraData) public returns (bool success){

        transferFrom(msg.sender, _to, _value);

        tokenRecipient receiver = tokenRecipient(_to);

        if (receiver.tokenFallback(msg.sender, _value, _extraData)) {
            emit DataSentToAnotherContract(msg.sender, _to, _extraData);
            return true;
        }
        return false;
    }  

     
    function transferAllAndCall(address _to, bytes _extraData) public returns (bool success){
        return transferAndCall(_to, balanceOf[msg.sender], _extraData);
    }

}