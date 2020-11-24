 

pragma solidity ^0.4.11;

 
contract SaintArnouldToken {
    string public constant name = "Saint Arnould Token";
    string public constant symbol = "SAT";
    uint8 public constant decimals = 18;   

    uint256 public constant tokenCreationRate = 5000;   
    uint256 public constant firstTokenCap = 10 ether * tokenCreationRate; 
    uint256 public constant secondTokenCap = 920 ether * tokenCreationRate;  

    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public locked_allocation;
    uint256 public unlockingBlock;

     
    address public founders;

     
    bool public funding_ended = false;

     
    uint256 totalTokens;

    mapping (address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function SaintArnouldToken(address _founders,
                               uint256 _fundingStartBlock,
                               uint256 _fundingEndBlock) {

        if (_founders == 0) throw;
        if (_fundingStartBlock <= block.number) throw;
        if (_fundingEndBlock   <= _fundingStartBlock) throw;

        founders = _founders;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }

     
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
         
        if (!funding_ended) throw;
        if (msg.sender == founders) throw;
        var senderBalance = balances[msg.sender];
        if (senderBalance >= _value && _value > 0) {
            senderBalance -= _value;
            balances[msg.sender] = senderBalance;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function totalSupply() external constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) external constant returns (uint256) {
        return balances[_owner];
    }

     

     
     
     
    function buy(address _sender) internal {
         
        if (funding_ended) throw;
         
        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingEndBlock) throw;

         
        if (msg.value == 0) throw;

        var numTokens = msg.value * tokenCreationRate;
        totalTokens += numTokens;

         
        balances[_sender] += numTokens;

         
        founders.transfer(msg.value);

         
        Transfer(0, _sender, numTokens);
    }

     
    function finalize() external {
        if (block.number <= fundingEndBlock) throw;

         
        locked_allocation = totalTokens * 10 / 100;
        balances[founders] = locked_allocation;
        totalTokens += locked_allocation;
        
        unlockingBlock = block.number + 864000;    
        funding_ended = true;
    }

    function transferFounders(address _to, uint256 _value) public returns (bool) {
        if (!funding_ended) throw;
        if (block.number <= unlockingBlock) throw;
        if (msg.sender != founders) throw;
        var senderBalance = balances[msg.sender];
        if (senderBalance >= _value && _value > 0) {
            senderBalance -= _value;
            balances[msg.sender] = senderBalance;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

     
    function() public payable {
        buy(msg.sender);
    }
}