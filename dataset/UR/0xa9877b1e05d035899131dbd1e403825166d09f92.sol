 

pragma solidity ^0.4.18;

 

contract ERC20 {
    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract MNTToken is ERC20, Owned {
     
    string public name = "Media Network Token";
    string public symbol = "MNT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;  
    uint256 public maxSupply = 125 * 10**6 * 10**18;
    address public cjTeamWallet = 0x9887c2da3aC5449F3d62d4A04372a4724c21f54C;

     
    mapping (address => uint256) public balanceOf;

     
    mapping (address => mapping (address => uint256)) public allowance;


     
    function MNTToken(
        address cjTeam
    ) public {
         
        totalEthRaised = 0;
         
        cjTeamWallet = cjTeam;
    }
	
    function changeCJTeamWallet(address newWallet) public onlyOwner {
        cjTeamWallet = newWallet;
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);                                
        require(balanceOf[_from] >= _value);                 
        require(balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) public returns (bool success) 
    {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(
        address _spender, 
        uint256 _value
    ) public returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOf[_owner];
    }

     
    function allowance(
        address _owner, 
        address _spender
    ) public constant returns (uint256 remaining)
    {
        return allowance[_owner][_spender];
    }

     
    function totalSupply() public constant returns (uint256 supply) {
        return totalSupply;
    }

     
     
     

    bool saleHasStarted = false;
    bool saleHasEnded = false;
    uint256 public saleEndTime   = 1518649200;  
    uint256 public saleStartTime = 1513435000;  
    uint256 public maxEthToRaise = 7500 * 10**18;
    uint256 public totalEthRaised;
    uint256 public ethAvailable;
    uint256 public eth2mnt = 10000;  

          
    function _mintTokens (address _to, uint256 _amount) internal {             
        require(balanceOf[_to] + _amount >= balanceOf[_to]);  
        require(totalSupply + _amount <= maxSupply);
        totalSupply += _amount;                                       
        balanceOf[_to] += _amount;                                
        Transfer(0x0, _to, _amount);                             
    }


       
    function () public payable {
        require(msg.value != 0);
        require(!(saleHasEnded || now > saleEndTime));  
        if (!saleHasStarted) {                                                 
            if (now >= saleStartTime) {                              
                saleHasStarted = true;                                            
            } else {
                require(false);
            }
        }     
     
        if (maxEthToRaise > (totalEthRaised + msg.value)) {                  
            totalEthRaised += msg.value;                                     
            ethAvailable += msg.value;
            _mintTokens(msg.sender, msg.value * eth2mnt);
            cjTeamWallet.transfer(msg.value); 
        } else {                                                               
            uint maxContribution = maxEthToRaise - totalEthRaised;             
            totalEthRaised += maxContribution;  
            ethAvailable += maxContribution;
            _mintTokens(msg.sender, maxContribution * eth2mnt);
            uint toReturn = msg.value - maxContribution;                        
            saleHasEnded = true;
            msg.sender.transfer(toReturn);                                   
            cjTeamWallet.transfer(msg.value-toReturn);       
        }
    } 

     
    function endOfSaleFullWithdrawal() public onlyOwner {
        if (saleHasEnded || now > saleEndTime) {
             
            cjTeamWallet.transfer(this.balance);
            ethAvailable = 0;
             
            _mintTokens (cjTeamWallet, 50 * 10**6 * 10**18);  
        }
    }

     
    function partialWithdrawal(uint256 toWithdraw) public onlyOwner {
        cjTeamWallet.transfer(toWithdraw);
        ethAvailable -= toWithdraw;
    }
}