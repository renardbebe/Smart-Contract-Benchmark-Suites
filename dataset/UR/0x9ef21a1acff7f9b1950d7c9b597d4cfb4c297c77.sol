 

pragma solidity ^0.4.11;

contract owned {
    address public owner;
 
    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract doccoin is owned {
     
    string public name = "DocCoin";
    string public symbol = "Doc";
    uint8 public decimals = 18;
     
    uint256 public totalSupply = 200000000000000000000000000;
    address public crowdsaleContract;

    uint sendingBanPeriod = 1520726400;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
    
    modifier canSend() {
        require ( msg.sender == owner ||  now > sendingBanPeriod || msg.sender == crowdsaleContract);
        _;
    }
    
     
    function doccoin(
    ) public {
        balanceOf[msg.sender] = totalSupply;                 
    }
    
    function setCrowdsaleContract(address contractAddress) onlyOwner {
        crowdsaleContract = contractAddress;
    }
     
     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
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

     
    function transfer(address _to, uint256 _value) public canSend {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public canSend returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
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


contract DoccoinPreICO is owned {
    
    address public wallet1 = address(0x0028D118C0c892e5afaF6C10d79D3922bC76840B);
    address public wallet2 = address(0xd7df9e4f97a7bdbff9799e29b9689515af2da3a6);
    
    uint public fundingGoal;
    uint public amountRaised;
    uint public beginTime = 1516838400;
    uint public endTime = 1517529600;
    uint public price = 100 szabo;
    doccoin public tokenReward;

    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function DoccoinPreICO(
        doccoin addressOfTokenUsedAsReward
    ) {
        tokenReward = addressOfTokenUsedAsReward;
    }
    
     
    function withdrawTokens() onlyOwner {
        tokenReward.transfer(msg.sender, tokenReward.balanceOf(this));
        FundTransfer(msg.sender, tokenReward.balanceOf(this), false);
    }
    
     
    function buyTokens(address beneficiary) payable {
        require(msg.value >= 200 finney);
        uint amount = msg.value;
        amountRaised += amount;
        tokenReward.transfer(beneficiary, amount*1000000000000000000/price);
        FundTransfer(beneficiary, amount, true);
        wallet1.transfer(msg.value*90/100);
        wallet2.transfer(msg.value*10/100);
        
    }

     
    function () payable onlyCrowdsalePeriod {
        buyTokens(msg.sender);
    }

    modifier onlyCrowdsalePeriod() { 
        require ( now >= beginTime && now <= endTime ) ;
        _; 
    }

    

}