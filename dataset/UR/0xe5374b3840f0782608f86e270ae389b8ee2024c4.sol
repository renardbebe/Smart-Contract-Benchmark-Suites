 

pragma solidity >=0.4.24 <0.6.0;

 


 
 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
         
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

 

 
 
contract allowanceRecipient {
    function receiveApproval(address _from, uint256 _value, address _inContract, bytes _extraData) public returns (bool);
}

 
contract tokenRecipient {
    function tokenFallback(address _from, uint256 _value, bytes _extraData) public returns (bool);
}

 

     
     
    string public name = "EthID Tokens";

     
     
    string public symbol = "EthID";

     
     
    uint8 public decimals = 0;

     
     
    uint256 public totalSupply;

     
     
    mapping(address => uint256) public balanceOf;

     
     
    mapping(address => mapping(address => uint256)) public allowance;

     

     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed spender, uint256 value);

     
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes _extraData);


     

    address public owner;  

     
     
    address private newOwner;

    function changeOwnerStart(address _newOwner) public {
         
        require(msg.sender == owner);

        newOwner = _newOwner;
        emit ChangeOwnerStarted(msg.sender, _newOwner);
    }  
    event ChangeOwnerStarted (address indexed startedBy, address indexed newOwner);

    function changeOwnerAccept() public {
         
        require(msg.sender == newOwner);
         
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }  
    event OwnerChanged(address indexed from, address indexed to);

     

    constructor() public {
         
        owner = msg.sender;
         
        totalSupply = 100 * 1000000;
        balanceOf[owner] = totalSupply;
    }


     
    event DividendsPaid(address indexed to, uint256 tokensBurned, uint256 sumInWeiPaid);

     
    function takeDividends(uint256 valueInTokens) public returns (bool) {

        require(address(this).balance > 0);
        require(totalSupply > 0);

        uint256 sumToPay = (address(this).balance / totalSupply).mul(valueInTokens);

        totalSupply = totalSupply.sub(valueInTokens);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(valueInTokens);

        msg.sender.transfer(sumToPay);

        emit DividendsPaid(msg.sender, valueInTokens, sumToPay);

        return true;
    }

     
    event WithdrawalByOwner(uint256 value, address indexed to);  
    function withdrawAllByOwner() public {
         
        require(msg.sender == owner);
         
        require(totalSupply == 0);

        uint256 sumToWithdraw = address(this).balance;
        owner.transfer(sumToWithdraw);
        emit WithdrawalByOwner(sumToWithdraw, owner);
    }

     
     

     
    function transfer(address _to, uint256 _value) public returns (bool){
        if (_to == address(this)) {
            return takeDividends(_value);
        } else {
            return transferFrom(msg.sender, _to, _value);
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

         
        require(_value >= 0);

         
        require(msg.sender == _from || _value <= allowance[_from][msg.sender]);

         
        require(_value <= balanceOf[_from]);

         
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
         
        balanceOf[_to] = balanceOf[_to].add(_value);

         
        if (_from != msg.sender) {
             
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

     
    function() public payable {
         
    }

}