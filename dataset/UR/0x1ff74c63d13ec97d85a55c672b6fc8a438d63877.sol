 

pragma solidity ^0.4.6;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owned {

     
    address public owner;

     
    address public issuer;

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

     
    modifier onlyIssuer() {
        if (msg.sender != owner && msg.sender != issuer) throw;
        _;
    }

     
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

 
 
contract Token {
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Mail is Owned, Token {

    using SafeMath for uint256;

     
    string public standard = "Token 0.2";

     
    string public name = "Ethereum Mail";

     
    string public symbol = "MAIL";

     
    uint8 public decimals = 0;
    
     
    uint256 public freeToUseTokens = 10 * 10 ** 6;  

     
    mapping (bytes32 => Token) public tokens;
    
     
    uint256 public maxTotalSupply = 10 ** 9;  

     
    bool public locked;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public usableBalances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    uint256 public currentMessageNumber;
    
    struct Message {
        bytes32 content;
        uint256 weight;
        uint256 validUntil;
        uint256 time;
        bytes32 attachmentSymbol;
        uint256 attachmentValue;
        address from;
        address[] to;
        address[] read;
    }
    
    mapping (uint256 => Message) messages;
    
    struct UnreadMessage {
        uint256 id;
        bool isOpened;
        bool free;
        address from;
        uint256 time;
        uint256 weight;
    }
    
    mapping (address => UnreadMessage[]) public unreadMessages;
    mapping (address => uint256) public unreadMessageCount;
    uint[] indexesUnread;
    uint[] indexesRead;
    mapping (address => uint256) public lastReceivedMessage;

     
    function setIssuer(address _issuer) onlyOwner {
        issuer = _issuer;
    }
    
     
    function unlock() onlyOwner returns (bool success)  {
        locked = false;
        return true;
    }
    
     
    function invalidateMail(uint256 _number) {
        if (messages[_number].validUntil >= now) {
            throw;
        }
        
        if (messages[_number].attachmentSymbol.length != 0x0 && messages[_number].attachmentValue > 0) {
            Token token = tokens[messages[_number].attachmentSymbol];
            token.transfer(messages[_number].from, messages[_number].attachmentValue.mul(messages[_number].to.length.sub(messages[_number].read.length)).div(messages[_number].to.length));
        }
        
        uint256 i = 0;
        while (i < messages[_number].to.length) {
            address recipient = messages[_number].to[i];

            for (uint a = 0; a < unreadMessages[recipient].length; ++a) {
                if (unreadMessages[recipient][a].id == _number) {

                    if (!unreadMessages[recipient][a].isOpened) {
                        unreadMessages[recipient][a].weight = 0;
                        unreadMessages[recipient][a].time = 0;

                        uint256 value = messages[_number].weight.div(messages[_number].to.length);

                        unreadMessageCount[recipient]--;
                        balances[recipient] = balances[recipient].sub(value);

                        if (!unreadMessages[recipient][a].free) {
                            usableBalances[messages[_number].from] = usableBalances[messages[_number].from].add(value);
                            balances[messages[_number].from] = balances[messages[_number].from].add(value);
                        }
                    }

                    break;
                }
            }
            
            i++;
        }
    }
    
     
    function getUnreadMessageCount(address _userAddress) constant returns (uint256 count)  {
        uint256 unreadCount;
        for (uint i = 0; i < unreadMessageCount[_userAddress]; ++i) {
            if (unreadMessages[_userAddress][i].isOpened == false) {
                unreadCount++;    
            }
        }
        
        return unreadCount;
    }
    

     
    function getUnreadMessages(address _userAddress) constant returns (uint[] mmessages)  {
        for (uint i = 0; i < unreadMessageCount[_userAddress]; ++i) {
            if (unreadMessages[_userAddress][i].isOpened == false) {
                indexesUnread.push(unreadMessages[_userAddress][i].id);
            }
        }
        
        return indexesUnread;
    }


    function getUnreadMessagesArrayContent(uint256 _number) public constant returns(uint256, bool, address, uint256, uint256) {
        for (uint a = 0; a < unreadMessageCount[msg.sender]; ++a) {
            if (unreadMessages[msg.sender][a].id == _number) {
                return (unreadMessages[msg.sender][a].id,unreadMessages[msg.sender][a].isOpened,unreadMessages[msg.sender][a].from, unreadMessages[msg.sender][a].time,unreadMessages[msg.sender][a].weight);
            }
        }
    }

     
    function getReadMessages(address _userAddress) constant returns (uint[] mmessages)  {        
        for (uint i = 0; i < unreadMessageCount[_userAddress]; ++i) {
            if (unreadMessages[_userAddress][i].isOpened == true) {
                indexesRead.push(unreadMessages[_userAddress][i].id);
            }
        }
        
        return indexesRead;
    }
    
     
    function addToken(address _tokenAddress, bytes32 _symbol) onlyOwner returns (bool success)  {
        Token token = Token(_tokenAddress);
        tokens[_symbol] = token;
        
        return true;
    }

     
    function lock() onlyOwner returns (bool success)  {
        locked = true;
        return true;
    }
    
     
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }
    
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
     
    function () {
        throw;
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {

         
        if (locked) {
            throw;
        }

         
        if (balances[msg.sender] < _value || usableBalances[msg.sender] < _value) {
            throw;
        }

         
        if (balances[_to] + _value < balances[_to])  {
            throw;
        }

         
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        usableBalances[msg.sender] -= _value;
        usableBalances[_to] += _value;

         
        Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

          
        if (locked) {
            throw;
        }

         
        if (balances[_from] < _value || usableBalances[_from] < _value) {
            throw;
        }

         
        if (balances[_to] + _value < balances[_to]) {
            throw;
        }

         
        if (_value > allowed[_from][msg.sender]) {
            throw;
        }

         
        balances[_to] += _value;
        balances[_from] -= _value;
        
        usableBalances[_from] -= _value;
        usableBalances[_to] += _value;

         
        allowed[_from][msg.sender] -= _value;

         
        Transfer(_from, _to, _value);
        
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {

         
        if (locked) {
            throw;
        }

         
        allowed[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

     
    function sendMail(address[] _to, uint256 _weight, bytes32 _hashedMessage, uint256 _validUntil, bytes32 _attachmentToken, uint256 _attachmentAmount) {
        bool useFreeTokens = false;
        if (_weight == 0 && freeToUseTokens > 0) {
            _weight = _to.length;
            useFreeTokens = true;
        }

        if ((!useFreeTokens && usableBalances[msg.sender] < _weight) || _weight < _to.length) {
            throw;
        }
        
        messages[currentMessageNumber].content = _hashedMessage;
        messages[currentMessageNumber].validUntil = _validUntil;
        messages[currentMessageNumber].time = now;
        messages[currentMessageNumber].from = msg.sender;
        messages[currentMessageNumber].to = _to;
        
        if (_attachmentToken != "") {
            Token token = tokens[_attachmentToken];
            
            if (!token.transferFrom(msg.sender, address(this), _attachmentAmount)) {
                throw;
            }
            
            messages[currentMessageNumber].attachmentSymbol = _attachmentToken;
            messages[currentMessageNumber].attachmentValue = _attachmentAmount;
        }
        
        UnreadMessage memory currentUnreadMessage;
        currentUnreadMessage.id = currentMessageNumber;
        currentUnreadMessage.isOpened = false;
        currentUnreadMessage.from = msg.sender;
        currentUnreadMessage.time = now;
        currentUnreadMessage.weight = _weight;
        currentUnreadMessage.free = useFreeTokens;

        uint256 i = 0;
        uint256 duplicateWeight = 0;
        
        while (i < _to.length) {
            if (lastReceivedMessage[_to[i]] == currentMessageNumber) {
                i++;
                duplicateWeight = duplicateWeight.add(_weight.div(_to.length));
                continue;
            }

            lastReceivedMessage[_to[i]] = currentMessageNumber;
        
            unreadMessages[_to[i]].push(currentUnreadMessage);
        
            unreadMessageCount[_to[i]]++;
            balances[_to[i]] = balances[_to[i]].add(_weight.div(_to.length));
            i++;
        }
        
        if (useFreeTokens) {
            freeToUseTokens = freeToUseTokens.sub(_weight.sub(duplicateWeight));
        } else {
            usableBalances[msg.sender] = usableBalances[msg.sender].sub(_weight.sub(duplicateWeight));
            balances[msg.sender] = balances[msg.sender].sub(_weight.sub(duplicateWeight));
        }  

        messages[currentMessageNumber].weight = _weight.sub(duplicateWeight);  

        currentMessageNumber++;
    }
    
    function getUnreadMessage(uint256 _number) constant returns (UnreadMessage unread) {
        for (uint a = 0; a < unreadMessages[msg.sender].length; ++a) {
            if (unreadMessages[msg.sender][a].id == _number) {
                return unreadMessages[msg.sender][a];
            }
        }
    }
    
     
    function openMail(uint256 _number) returns (bool success) {
        UnreadMessage memory currentUnreadMessage = getUnreadMessage(_number);

         
        if (currentUnreadMessage.isOpened || currentUnreadMessage.weight == 0) {
            throw;
        }
        
        if (messages[_number].attachmentSymbol != 0x0 && messages[_number].attachmentValue > 0) {
            Token token = tokens[messages[_number].attachmentSymbol];
            token.transfer(msg.sender, messages[_number].attachmentValue.div(messages[_number].to.length));
        }
        
        for (uint a = 0; a < unreadMessages[msg.sender].length; ++a) {
            if (unreadMessages[msg.sender][a].id == _number) {
                unreadMessages[msg.sender][a].isOpened = true;
            }
        }
        
        messages[_number].read.push(msg.sender);
        
        usableBalances[msg.sender] = usableBalances[msg.sender].add(messages[_number].weight.div(messages[_number].to.length));
        
        return true;
    }
    
     
    function getMail(uint256 _number) constant returns (bytes32 message) {
        UnreadMessage memory currentUnreadMessage = getUnreadMessage(_number);
        if (!currentUnreadMessage.isOpened || currentUnreadMessage.weight == 0) {
            throw;
        }
        
        return messages[_number].content;
    }
    
     
    function issue(address _recipient, uint256 _value) onlyIssuer returns (bool success) {

        if (totalSupply.add(_value) > maxTotalSupply) {
            return;
        }
        
         
        balances[_recipient] = balances[_recipient].add(_value);
        usableBalances[_recipient] = usableBalances[_recipient].add(_value);
        totalSupply = totalSupply.add(_value);

        return true;
    }
    
    function Mail() {
        balances[msg.sender] = 0;
        totalSupply = 0;
        locked = false;
    }
}