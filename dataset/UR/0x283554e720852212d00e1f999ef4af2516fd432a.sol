 

pragma solidity 0.4.25;


 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "Bad maths.");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "Bad maths.");
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b, "Bad maths.");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "Bad maths.");
        c = a / b;
    }
}


 
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
contract Owned {
    address internal owner;
    address internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner may execute this function.");
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

     
    function disown() public onlyOwner() {
        delete owner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner, "You have not been selected as the new owner.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}





 
contract SnowdenToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 internal accountCount = 0;
    uint256 internal _totalSupply = 0;
    bool internal readOnly = false;
    uint256 internal constant MAX_256 = 2**256 - 1;
    mapping(address => bool) public ignoreDividend;

    event DividendGivenEvent(uint64 dividendPercentage);

    mapping(address => uint256) public freezeUntil;

    mapping(address => address) internal addressLinkedList;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

     
    constructor(uint256 supply, address[] addresses, uint256[] tokens, uint256[] freezeList, address[] ignoreList) public {
        symbol = "SNOW";
        name = "Snowden";
        decimals = 0;
        _totalSupply = supply;  
        balances[address(0)] = _totalSupply;

        uint256 totalAddresses = addresses.length;
        uint256 totalTokens = tokens.length;

         
        require(totalAddresses > 0 && totalTokens > 0, "Must be a positive number of addresses and tokens.");

         
        require(totalAddresses == totalTokens, "Must be tokens assigned to all addresses.");

        uint256 aggregateTokens = 0;

        for (uint256 i = 0; i < totalAddresses; i++) {
             
             
             
            require(tokens[i] > 0, "No empty tokens allowed.");

            aggregateTokens = aggregateTokens + tokens[i];

             
            require(aggregateTokens <= supply, "Supply is not enough for demand.");

            giveReserveTo(addresses[i], tokens[i]);
            freezeUntil[addresses[i]] = freezeList[i];
        }

        ignoreDividend[address(this)] = true;
        ignoreDividend[msg.sender] = true;
        for (i = 0; i < ignoreList.length; i++) {
            ignoreDividend[ignoreList[i]] = true;
        }
    }

     
    function () public payable {
        revert();
    }

     
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;  
    }

     
    function list() public view returns (address[], uint256[]) {
        address[] memory addrs = new address[](accountCount);
        uint256[] memory tokens = new uint256[](accountCount);

        uint256 i = 0;
        address current = addressLinkedList[0];
        while (current != 0) {
            addrs[i] = current;
            tokens[i] = balances[current];

            current = addressLinkedList[current];
            i++;
        }

        return (addrs, tokens);
    }

     
    function remainingTokens() public view returns(uint256) {
        return balances[address(0)];
    }

     
    function isReadOnly() public view returns(bool) {
        return readOnly;
    }

     
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }

     
    function requireTrade(address from) public view {
        require(!readOnly, "Read only mode engaged");

        uint256 i = 0;
        address current = addressLinkedList[0];
        while (current != 0) {
            if(current == from) {
                uint256 timestamp = freezeUntil[current];
                require(timestamp < block.timestamp, "Trades from your account are temporarily not possible. This is due to ICO rules.");

                break;
            }

            current = addressLinkedList[current];
            i++;
        }
    }

     
    function transfer(address to, uint256 tokens) public returns (bool success) {
        requireTrade(msg.sender);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);

        ensureInAccountList(to);

        return true;
    }

     
    function approve(address spender, uint256 tokens) public returns (bool success) {
        requireTrade(msg.sender);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        requireTrade(from);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);

        ensureInAccountList(from);
        ensureInAccountList(to);

        return true;
    }

     
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        requireTrade(tokenOwner);
        return allowed[tokenOwner][spender];
    }

     
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        requireTrade(msg.sender);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
    function transferAnyERC20Token(address addr, uint256 tokens) public onlyOwner returns (bool success) {
        requireTrade(addr);
        return ERC20Interface(addr).transfer(owner, tokens);
    }

     
    function giveReserveTo(address to, uint256 tokens) public onlyOwner {
        require(!readOnly, "Read only mode engaged");

        balances[address(0)] = balances[address(0)].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(address(0), to, tokens);

        ensureInAccountList(to);
    }

     
    function giveDividend(uint64 percentage) public onlyOwner {
        require(!readOnly, "Read only mode engaged");

        require(percentage > 0, "Percentage must be more than 0 (10000 = 1%)");  
        require(percentage <= 500000, "Percentage may not be larger than 500000 (50%)");  

        emit DividendGivenEvent(percentage);

        address current = addressLinkedList[0];
        while (current != 0) {
            bool found = ignoreDividend[current];
            if(!found) {
                uint256 extraTokens = (balances[current] * percentage) / 1000000;
                giveReserveTo(current, extraTokens);
            }
            current = addressLinkedList[current];
        }
    }

     
    function setReadOnly(bool enabled) public onlyOwner {
        readOnly = enabled;
    }

     
    function addToAccountList(address addr) internal {
        require(!readOnly, "Read only mode engaged");

        addressLinkedList[addr] = addressLinkedList[0x0];
        addressLinkedList[0x0] = addr;
        accountCount++;
    }

     
    function removeFromAccountList(address addr) internal {
        require(!readOnly, "Read only mode engaged");

        uint16 i = 0;
        bool found = false;
        address parent;
        address current = addressLinkedList[0];
        while (true) {
            if (addressLinkedList[current] == addr) {
                parent = current;
                found = true;
                break;
            }
            current = addressLinkedList[current];

            if (i++ > accountCount) break;
        }

        require(found, "Account was not found to remove.");

        addressLinkedList[parent] = addressLinkedList[addressLinkedList[parent]];
        delete addressLinkedList[addr];

        if (balances[addr] > 0) {
            balances[address(0)] += balances[addr];
        }

        delete balances[addr];

        accountCount--;
    }

     
    function ensureInAccountList(address addr) internal {
        require(!readOnly, "Read only mode engaged");

        bool found = false;
        address current = addressLinkedList[0];
        while (current != 0) {
            if (current == addr) {
                found = true;
                break;
            }
            current = addressLinkedList[current];
        }
        if (!found) {
            addToAccountList(addr);
        }
    }
}