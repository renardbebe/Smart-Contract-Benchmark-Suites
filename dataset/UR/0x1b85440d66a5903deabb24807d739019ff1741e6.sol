 

 




library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract Subrosa {
  using SafeMath for uint256;
     

     
     
    event Deposit(address _from, uint256 _amount);
     
    event WithDraw(address _to, uint256 _amount);

     
    address public owner;

     
    address public contractAddress;

     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

     
    function Subrosa() public{
        owner = 0x193129A669A6Fd24Fc261028570023e91F123573;
        contractAddress = this;
    }

     
     
    function () public payable {
        emit Deposit(msg.sender, msg.value);
    }

     
    function withDraw() public onlyOwner () {
        owner.transfer(contractAddress.balance);
        emit WithDraw(owner, contractAddress.balance);
    }

     
     
    function withDrawAmount(uint256 amount) public onlyOwner{
        require(amount <= contractAddress.balance);
        owner.transfer(amount);
        emit WithDraw(owner, amount);
    }

     
     
    function getBalance() public constant returns(uint256 balance){
        return contractAddress.balance;
    }
}

 