 

pragma solidity ^0.4.25;

 
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


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
    constructor() public
    {
       owner = msg.sender;
    }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}


 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}

contract BaconCoin is BurnableToken, Ownable {

    string public constant name = "BaconCoin";
    string public constant symbol = "BAK";
    uint public constant decimals = 8;
    uint256 public constant initialSupply = 2200000000 * (10 ** uint256(decimals));

     
    struct Wallet {
        uint256 balance;
        uint256 tokenBalance;
        mapping(address => bool) authed;   
        uint64 seedNonce;
        uint64 withdrawNonce;
    }
    
    address[] public admins;

    mapping(bytes32 => Wallet) private wallets;
    mapping(address => bool) private isAdmin;

    uint256 private agentBalance;
    uint256 private agentTokenBalance;
    
    modifier onlyAdmin {
        require(isAdmin[msg.sender]);
        _;
    }

    modifier onlyRootAdmin {
        require(msg.sender == admins[0]);
        _;
    }

    event Auth(
        bytes32 indexed walletID,
        address indexed agent
    );

    event Withdraw(
        bytes32 indexed walletID,
        uint256 indexed nonce,
        uint256 indexed value,
        address recipient
    );
    
    event Deposit(
        bytes32 indexed walletID,
        address indexed sender,
        uint256 indexed value
    );

    event Seed(
        bytes32 indexed walletID,
        uint256 indexed nonce,
        uint256 indexed value
    );

    event Gain(
        bytes32 indexed walletID,
        uint256 indexed requestID,
        uint256 indexed value
    );

    event DepositToken(
        bytes32 indexed walletID,
        address indexed sender, 
        uint256 indexed amount
    );
    
    event WithdrawToken(
        bytes32 indexed walletID,
        uint256 indexed nonce,
        uint256 indexed amount,
        address recipient
    );
    
    event SeedToken(
        bytes32 indexed walletID,
        uint256 indexed nonce,
        uint256 indexed amount
    );

    event GainToken(
        bytes32 indexed walletID,
        uint256 indexed requestID,
        uint256 indexed amount
    );
    
    constructor() public
    {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply; 

        admins.push(msg.sender);
        isAdmin[msg.sender] = true;
    }

    function auth(
        bytes32[] walletIDs,
        bytes32[] nameIDs,
        address[] agents,
        uint8[] v, bytes32[] r, bytes32[] s) onlyAdmin public
    {
        require(
            walletIDs.length == nameIDs.length &&
            walletIDs.length == agents.length &&
            walletIDs.length == v.length &&
            walletIDs.length == r.length &&
            walletIDs.length == s.length
        );

        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            address agent = agents[i];

            address signer = getMessageSigner(
                getAuthDigest(walletID, agent), v[i], r[i], s[i]
            );

            Wallet storage wallet = wallets[walletID];

            if (wallet.authed[signer] || walletID == getWalletDigest(nameIDs[i], signer)) {
                wallet.authed[agent] = true;

                emit Auth(walletID, agent);
            }
        }
    }

    function deposit( bytes32 walletID) payable public
    {
        wallets[walletID].balance += msg.value;

        emit Deposit(walletID, msg.sender, msg.value);
    }

    function withdraw(
        bytes32[] walletIDs,
        address[] receivers,
        uint256[] values,
        uint64[] nonces,
        uint8[] v, bytes32[] r, bytes32[] s) onlyAdmin public
    {
        require(
            walletIDs.length == receivers.length &&
            walletIDs.length == values.length &&
            walletIDs.length == nonces.length &&
            walletIDs.length == v.length &&
            walletIDs.length == r.length &&
            walletIDs.length == s.length
        );

        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            address receiver = receivers[i];
            uint256 value = values[i];
            uint64 nonce = nonces[i];

            address signer = getMessageSigner(
                getWithdrawDigest(walletID, receiver, value, nonce), v[i], r[i], s[i]
            );

            Wallet storage wallet = wallets[walletID];

            if (
                wallet.withdrawNonce < nonce &&
                wallet.balance >= value &&
                wallet.authed[signer] &&
                receiver.send(value)
            ) {
                wallet.withdrawNonce = nonce;
                wallet.balance -= value;

                emit Withdraw(walletID, nonce, value, receiver);
            }
        }
    }

    function seed(
        bytes32[] walletIDs,
        uint256[] values,
        uint64[] nonces,
        uint8[] v, bytes32[] r, bytes32[] s) onlyAdmin public
    {
        require(
            walletIDs.length == values.length &&
            walletIDs.length == nonces.length &&
            walletIDs.length == v.length &&
            walletIDs.length == r.length &&
            walletIDs.length == s.length
        );

        uint256 addition = 0;

        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            uint256 value = values[i];
            uint64 nonce = nonces[i];

            address signer = getMessageSigner(
                getSeedDigest(walletID, value, nonce), v[i], r[i], s[i]
            );

            Wallet storage wallet = wallets[walletID];

            if (
                wallet.seedNonce < nonce &&
                wallet.balance >= value &&
                wallet.authed[signer]
            ) {
                wallet.seedNonce = nonce;
                wallet.balance -= value;

                emit Seed(walletID, nonce, value);

                addition += value;
            }
        }

        agentBalance += addition;
    }


    function gain(
        bytes32[] walletIDs,
        uint256[] recordIDs,
        uint256[] values) onlyAdmin public
    {
        require(
            walletIDs.length == recordIDs.length &&
            walletIDs.length == values.length
        );

        uint256 remaining = agentBalance;

        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            uint256 value = values[i];

            require(value <= remaining);

            wallets[walletID].balance += value;
            remaining -= value;

            emit Gain(walletID, recordIDs[i], value);
        }

        agentBalance = remaining;
    }

    function getMessageSigner(
        bytes32 message,
        uint8 v, bytes32 r, bytes32 s) public pure returns(address)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedMessage = keccak256(
            abi.encodePacked(prefix, message)
        );
        return ecrecover(prefixedMessage, v, r, s);
    }

    function getNameDigest(
        string myname) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(myname));
    }

    function getWalletDigest(
        bytes32 myname,
        address root) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            myname, root
        ));
    }

    function getAuthDigest(
        bytes32 walletID,
        address agent) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            walletID, agent
        ));
    }

    function getSeedDigest(
        bytes32 walletID,
        uint256 value,
        uint64 nonce) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            walletID, value, nonce
        ));
    }

    function getWithdrawDigest(
        bytes32 walletID,
        address receiver,
        uint256 value,
        uint64 nonce) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            walletID, receiver, value, nonce
        ));
    }

    function getSeedNonce(
        bytes32 walletID) public view returns (uint256)
    {
        return wallets[walletID].seedNonce + 1;
    }

    function getWithdrawNonce(
        bytes32 walletID) public view returns (uint256)
    {
        return wallets[walletID].withdrawNonce + 1;
    }

    function getAuthStatus(
        bytes32 walletID,
        address member) public view returns (bool)
    {
        return wallets[walletID].authed[member];
    }

    function getBalance(
        bytes32 walletID) public view returns (uint256)
    {
        return wallets[walletID].balance;
    }
    
    function gettokenBalance(
        bytes32 walletID) public view returns (uint256)
    {
        return wallets[walletID].tokenBalance;
    }

    function getagentBalance() public view returns (uint256)
    {
      return agentBalance;
    }

    function getagentTokenBalance() public view returns (uint256)
    {
      return agentTokenBalance;
    }
    
    function removeAdmin(
        address oldAdmin) onlyRootAdmin public
    {
        require(isAdmin[oldAdmin] && admins[0] != oldAdmin);

        bool found = false;
        for (uint i = 1; i < admins.length - 1; i++) {
            if (!found && admins[i] == oldAdmin) {
                found = true;
            }
            if (found) {
                admins[i] = admins[i + 1];
            }
        }

        admins.length--;
        isAdmin[oldAdmin] = false;
    }

    function changeRootAdmin(
        address newRootAdmin) onlyRootAdmin public
    {
        if (isAdmin[newRootAdmin] && admins[0] != newRootAdmin) {
            removeAdmin(newRootAdmin);
        }
        admins[0] = newRootAdmin;
        isAdmin[newRootAdmin] = true;
    }

    function addAdmin(
        address newAdmin) onlyRootAdmin public
    {
        require(!isAdmin[newAdmin]);

        isAdmin[newAdmin] = true;
        admins.push(newAdmin);
    }
    
    function depositToken(bytes32 walletID, uint256 amount) public returns (bool)
    {
        require(amount > 0);
        require(approve(msg.sender, amount+1));
   
        uint256 _allowance = allowed[msg.sender][msg.sender];
        balances[msg.sender] = balances[msg.sender].sub(amount);

        wallets[walletID].tokenBalance = wallets[walletID].tokenBalance.add(amount);
        allowed[msg.sender][msg.sender] = _allowance.sub(amount);

        emit DepositToken(walletID, msg.sender, amount);
        return true;
    }
  
    function withdrawToken(
        bytes32[] walletIDs,
        address[] receivers,
        uint256[] amounts,
        uint64[] nonces,
        uint8[] v, bytes32[] r, bytes32[] s) onlyAdmin public returns (bool)
    {
        require(
            walletIDs.length == receivers.length &&
            walletIDs.length == amounts.length &&
            walletIDs.length == nonces.length &&
            walletIDs.length == v.length &&
            walletIDs.length == r.length &&
            walletIDs.length == s.length
        );

        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            address receiver = receivers[i];
            uint256 amount = amounts[i];
            uint64 nonce = nonces[i];
            
            address signer = getMessageSigner(
                getWithdrawDigest(walletID, receiver, amount, nonce), v[i], r[i], s[i]
            );
            Wallet storage wallet = wallets[walletID];
            if (
                wallet.withdrawNonce < nonce &&
                wallet.tokenBalance >= amount &&
                wallet.authed[signer]
            ) 
            {
                wallet.withdrawNonce = nonce;
                wallet.tokenBalance = wallet.tokenBalance.sub(amount);
		        balances[receiver] = balances[receiver].add(amount);
		       
                emit WithdrawToken(walletID, nonce, amount, receiver);
                return true;
            }
        }
    }

    function seedToken(
        bytes32[] walletIDs,
        uint256[] amounts,
        uint64[] nonces,
        uint8[] v, bytes32[] r, bytes32[] s) onlyAdmin public
    {
        require(
            walletIDs.length == amounts.length &&
            walletIDs.length == nonces.length &&
            walletIDs.length == v.length &&
            walletIDs.length == r.length &&
            walletIDs.length == s.length
        );
        
        uint256 addition = 0;

        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            uint256 amount = amounts[i];
            uint64 nonce = nonces[i];

            address signer = getMessageSigner(
                getSeedDigest(walletID, amount, nonce), v[i], r[i], s[i]
            );

            Wallet storage wallet = wallets[walletID];
            if (
                wallet.seedNonce < nonce &&
                wallet.tokenBalance >= amount &&
                wallet.authed[signer]
            ) {
                wallet.seedNonce = nonce;
                wallet.tokenBalance = wallet.tokenBalance.sub(amount);
                emit SeedToken(walletID, nonce, amount);
                addition += amount;
            }
        }

        agentTokenBalance += addition;
    }


    function gainToken(
        bytes32[] walletIDs,
        uint256[] recordIDs,
        uint256[] amounts) onlyAdmin public
    {
        require(
            walletIDs.length == recordIDs.length &&
            walletIDs.length == amounts.length
        );

        uint256 remaining = agentTokenBalance;
        
        
        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            uint256 amount = amounts[i];
            
            Wallet storage wallet = wallets[walletID];
            require(amount <= remaining);

            wallet.tokenBalance = wallet.tokenBalance.add(amount);
            remaining = remaining.sub(amount);

            emit GainToken(walletID, recordIDs[i], amount);
        }

        agentTokenBalance = remaining;
    }

}