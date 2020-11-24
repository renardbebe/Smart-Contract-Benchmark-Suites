 

 

pragma solidity 0.4.24;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        uint256 c = a / b;
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        uint256 c = a - b;
        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MOD_ERROR");
        return a % b;
    }
}

 
 
 
contract LibOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns(address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "NOT_OWNER");
        _;
    }

     
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

     
     
     
     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract LibWhitelist is LibOwnable {
    mapping (address => bool) public whitelist;
    address[] public allAddresses;

    event AddressAdded(address indexed adr);
    event AddressRemoved(address indexed adr);

     
    modifier onlyAddressInWhitelist {
        require(whitelist[msg.sender], "SENDER_NOT_IN_WHITELIST_ERROR");
        _;
    }

     
     
    function addAddress(address adr) external onlyOwner {
        emit AddressAdded(adr);
        whitelist[adr] = true;
        allAddresses.push(adr);
    }

     
     
    function removeAddress(address adr) external onlyOwner {
        emit AddressRemoved(adr);
        delete whitelist[adr];
        for(uint i = 0; i < allAddresses.length; i++){
            if(allAddresses[i] == adr) {
                allAddresses[i] = allAddresses[allAddresses.length - 1];
                allAddresses.length -= 1;
                break;
            }
        }
    }

     
    function getAllAddresses() external view returns (address[] memory) {
        return allAddresses;
    }
}

contract Proxy is LibWhitelist {
    using SafeMath for uint256;

    mapping( address => uint256 ) public balances;

    event Deposit(address owner, uint256 amount);
    event Withdraw(address owner, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function depositEther() public payable {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawEther(uint256 amount) public {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function () public payable {
        depositEther();
    }

     
     
     
     
     
    function transferFrom(address token, address from, address to, uint256 value)
        external
        onlyAddressInWhitelist
    {
        if (token == address(0)) {
            transferEther(from, to, value);
        } else {
            transferToken(token, from, to, value);
        }
    }

    function transferEther(address from, address to, uint256 value)
        internal
        onlyAddressInWhitelist
    {
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);

        emit Transfer(from, to, value);
    }

     
     
     
     
     
    function transferToken(address token, address from, address to, uint256 value)
        internal
        onlyAddressInWhitelist
    {
        assembly {

             
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)

             
             
            calldatacopy(4, 36, 96)

             
            let result := call(gas, token, 0, 0, 100, 0, 32)

             
             
             
             
            switch eq(result, 1)
            case 1 {
                switch or(eq(returndatasize, 0), and(eq(returndatasize, 32), gt(mload(0), 0)))
                case 1 {
                    return(0, 0)
                }
            }
        }

        revert("TOKEN_TRANSFER_FROM_ERROR");
    }
}