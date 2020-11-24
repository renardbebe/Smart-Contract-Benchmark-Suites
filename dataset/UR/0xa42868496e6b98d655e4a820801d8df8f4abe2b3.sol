 

pragma solidity ^0.4.16;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

contract KJC {
     
    string public name = "KimJ Coin";
    string public symbol = "KJC";
    uint8 public decimals = 18;
     
    uint256 public totalSupply =2000000* (10 ** 18);
    uint256 public totaldivineTokensIssued = 0;
    
    address owner = msg.sender;

     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => mapping (address => uint256)) public allowance;

     
    bool public saleEnabled = true;
    uint256 public totalEthereumRaised = 0;
    uint256 public KJCPerEthereum = 10000;
    
    function KJC() public {
        balanceOf[owner] += totalSupply;               
    }


     
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


     
    function _transfer(address _from, address _to, uint _value) internal 
    {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
         
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public 
    {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
     {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) 
    {
         
        if (_value != 0 && allowance[msg.sender][_spender] != 0) { return false; }
 
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) 
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function() public payable {
        require(saleEnabled);
        
        if (msg.value == 0) { return; }

        owner.transfer(msg.value);
        totalEthereumRaised += msg.value;

        uint256 tokensIssued = (msg.value * KJCPerEthereum);

         
        if (msg.value >= 10 finney) 
        {

            bytes20 divineHash = ripemd160(block.coinbase, block.number, block.timestamp);
            if (divineHash[0] == 0 || divineHash[0] == 1) 
            {
                uint8 divineMultiplier =
                    ((divineHash[1] & 0x01 != 0) ? 1 : 0) + ((divineHash[1] & 0x02 != 0) ? 1 : 0) +
                    ((divineHash[1] & 0x04 != 0) ? 1 : 0) + ((divineHash[1] & 0x08 != 0) ? 1 : 0);
                
                uint256 divineTokensIssued = (msg.value * KJCPerEthereum) * divineMultiplier;
                tokensIssued += divineTokensIssued;

                totaldivineTokensIssued += divineTokensIssued;
            }
        }

        totalSupply += tokensIssued;
        balanceOf[msg.sender] += tokensIssued;
        
        Transfer(address(this), msg.sender, tokensIssued);
    }

    function disablePurchasing() public
    {
        require(msg.sender == owner);
        saleEnabled = false;
    }

    function getStats() public constant returns (uint256, uint256, uint256, bool) {
        return (totalEthereumRaised, totalSupply, totaldivineTokensIssued, saleEnabled);
    }
}