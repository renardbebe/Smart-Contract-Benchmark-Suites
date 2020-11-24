 

pragma solidity ^0.4.18;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);  
        uint256 c = a / b;
        assert(a == b * c);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        assert(b <= a);
        assert(a == c + b);
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        assert(a == c - b);
        return c;
    }
}
contract QunQunTokenIssue {

    address public tokenContractAddress;
    uint16  public lastRate = 950;  
    uint256 public lastBlockNumber;
    uint256 public lastYearTotalSupply = 15 * 10 ** 26;  
    uint8   public inflateCount = 0;
    bool    public isFirstYear = true;  

    function QunQunTokenIssue (address _tokenContractAddress) public{
        tokenContractAddress = _tokenContractAddress;
        lastBlockNumber = block.number;
    }

    function getRate() internal returns (uint256){
        if(inflateCount == 10){
             
            if(lastRate > 100){
                lastRate -= 50;
            }
             
            inflateCount = 0;
        }
         
        return SafeMath.div(lastRate, 10);
    }

     
    function issue() public  {
         
        if(isFirstYear){
             
            require(SafeMath.sub(block.number, lastBlockNumber) > 2102400);
            isFirstYear = false;
        }
         
        require(SafeMath.sub(block.number, lastBlockNumber) > 210240);
        QunQunToken tokenContract = QunQunToken(tokenContractAddress);
         
        if(inflateCount == 10){
            lastYearTotalSupply = tokenContract.totalSupply();
        }
        uint256 amount = SafeMath.div(SafeMath.mul(lastYearTotalSupply, getRate()), 10000);
        require(amount > 0);
        tokenContract.issue(amount);
        lastBlockNumber = block.number;
        inflateCount += 1;
    }
}


interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract QunQunToken {

     
    string public name = 'QunQunCommunities';

    string public symbol = 'QUN';

    uint8 public decimals = 18;

    uint256 public totalSupply = 15 * 10 ** 26;

    address public issueContractAddress;
    address public owner;

     
    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     
    event Burn(address indexed from, uint256 value);
    event Issue(uint256 amount);

     
    function QunQunToken() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
         
        issueContractAddress = new QunQunTokenIssue(address(this));
    }

     
    function issue(uint256 amount) public {
        require(msg.sender == issueContractAddress);
        balanceOf[owner] = SafeMath.add(balanceOf[owner], amount);
        totalSupply = SafeMath.add(totalSupply, amount);
        Issue(amount);
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
         
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[msg.sender]);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
         
        balanceOf[msg.sender] -= _value;
         
        totalSupply -= _value;
         
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
         
        require(_value <= allowance[_from][msg.sender]);
         
        balanceOf[_from] -= _value;
         
        allowance[_from][msg.sender] -= _value;
         
        totalSupply -= _value;
         
        Burn(_from, _value);
        return true;
    }

}