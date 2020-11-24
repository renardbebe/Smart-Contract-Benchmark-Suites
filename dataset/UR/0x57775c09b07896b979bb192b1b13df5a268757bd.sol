 

pragma solidity ^0.4.17;

 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;

         
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);

        return a - b;
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        assert(c >= a);

        return c;
    }
}

 
 
 
contract Owned {

    address public owner;
    address public proposedOwner;

    event OwnershipTransferInitiated(address indexed _proposedOwner);
    event OwnershipTransferCompleted(address indexed _newOwner);


    function Owned() public {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }


    function isOwner(address _address) internal view returns (bool) {
        return (_address == owner);
    }


    function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
        proposedOwner = _proposedOwner;

        OwnershipTransferInitiated(_proposedOwner);

        return true;
    }


    function completeOwnershipTransfer() public returns (bool) {
        require(msg.sender == proposedOwner);

        owner = proposedOwner;
        proposedOwner = address(0);

        OwnershipTransferCompleted(owner);

        return true;
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

 
contract TokenSaleInterface {
    function endTime() public view returns (uint256);
}

 
contract FutureTokenSaleLockBox is Owned {
    using SafeMath for uint256;

     
    ERC20Interface public simpleToken;

     
    TokenSaleInterface public tokenSale;

     
    uint256 public unlockDate;

    event UnlockDateExtended(uint256 _newDate);
    event TokensTransferred(address indexed _to, uint256 _value);

     
    function FutureTokenSaleLockBox(ERC20Interface _simpleToken, TokenSaleInterface _tokenSale)
             Owned()
             public
    {
        require(address(_simpleToken) != address(0));
        require(address(_tokenSale)   != address(0));

        simpleToken = _simpleToken;
        tokenSale   = _tokenSale;
        uint256 endTime = tokenSale.endTime();

        require(endTime > 0);

        unlockDate  = endTime.add(26 weeks);
    }

     
    modifier onlyAfterUnlockDate() {
        require(hasUnlockDatePassed());
        _;
    }

     
    function currentTime() public view returns (uint256) {
        return now;
    }

     
    function hasUnlockDatePassed() public view returns (bool) {
        return currentTime() >= unlockDate;
    }

     
    function extendUnlockDate(uint256 _newDate) public onlyOwner returns (bool) {
        require(_newDate > unlockDate);

        unlockDate = _newDate;
        UnlockDateExtended(_newDate);

        return true;
    }

     
    function transfer(address _to, uint256 _value) public onlyOwner onlyAfterUnlockDate returns (bool) {
        require(simpleToken.transfer(_to, _value));

        TokensTransferred(_to, _value);

        return true;
    }
}