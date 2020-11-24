 

pragma solidity 0.4.17;

contract Ownable {
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}


contract TripCash is Ownable {

    uint256 public totalSupply = 5000000000 * 1 ether;


    string public constant name = "TripCash";
    string public constant symbol = "TASH";
    uint8 public constant decimals = 18;

    mapping (address => uint256) public balances;  
    mapping (address => mapping(address => uint256)) public allowed;
    mapping (address => bool) public notransfer;


    uint256 public startPreICO = 1523840400;  
    uint256 public endPreICO = 1528675199;  
    uint256 public startTime = 1529884800;  
    uint256 public endTime = 1532303999;  


    address public constant ownerWallet = 0x9dA14C46f0182D850B12866AB0f3e397Fbd4FaC4;  
    address public constant teamWallet1 = 0xe82F49A648FADaafd468E65a13C050434a4C4a6f ;  
    address public constant teamWallet2 = 0x16Eb7B7E232590787F1Fe3742acB1a1d0e43AF2A;  
    address public constant fundWallet = 0x949844acF5C722707d02A037D074cabe7474e0CB;  
    address public constant frozenWallet2y = 0xAc77c90b37AFd80D2227f74971e7c3ad3e29D1fb;  
    address public constant frozenWallet4y = 0x265B8e89DAbA5Bdc330E55cA826a9f2e0EFf0870;  

    uint256 public constant ownerPercent = 10;  
    uint256 public constant teamPercent = 10;  
    uint256 public constant bountyPercent = 10;  

    bool public transferAllowed = false;
    bool public refundToken = false;

     
    function TripCash() public {
        balances[owner] = totalSupply;
    }

     
    modifier canTransferToken(address _from) {
        if (_from != owner) {
            require(transferAllowed);
        }
        
        if (_from == teamWallet1) {
            require(now >= endTime + 15552000);
        }

        if (_from == teamWallet2) {
            require(now >= endTime + 31536000);
        }
        
        _;
    }

     
    modifier notAllowed(){
        require(!transferAllowed);
        _;
    }

     
    modifier saleIsOn() {
        require((now > startTime && now < endTime)||(now > startPreICO && now < endPreICO));
        _;
    }

     

    modifier canRefundToken() {
        require(refundToken);
        _;
    }

     
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        uint256 tokenValue = balances[owner];

        transfer(_newOwner, tokenValue);
        owner = _newOwner;

        OwnershipTransferred(owner, _newOwner);

    }

     
    function dappsBonusCalc(address _to, uint256 _value) onlyOwner saleIsOn() notAllowed public returns (bool) {

        require(_value != 0);
        transfer(_to, _value);
        notransfer[_to] = true;

        uint256 bountyTokenAmount = 0;
        uint256 ownerTokenAmount = 0;
        uint256 teamTokenAmount = 0;

         
        bountyTokenAmount = _value * bountyPercent / 60;

         
        ownerTokenAmount = _value * ownerPercent / 60;

         
        teamTokenAmount = _value * teamPercent / 60;
        
        transfer(ownerWallet, ownerTokenAmount);
        transfer(fundWallet, bountyTokenAmount);
        transfer(teamWallet1, teamTokenAmount);
        transfer(teamWallet2, teamTokenAmount);

        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
     
    function transfer(address _to, uint256 _value) canTransferToken(msg.sender) public returns (bool){
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        if (notransfer[msg.sender] == true) {
            notransfer[msg.sender] = false;
        }

        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) canTransferToken(_from) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;

        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     

    function rewarding(address _holder) public onlyOwner returns(uint){
        if(notransfer[_holder]==true){
            if(now >= endTime + 63072000){
                uint noTransfer2BonusYear = balances[_holder]*25 / 100;
                if (balances[fundWallet] >= noTransfer2BonusYear) {
                    balances[fundWallet] = balances[fundWallet] - noTransfer2BonusYear;
                    balances[_holder] = balances[_holder] + noTransfer2BonusYear;
                    assert(balances[_holder] >= noTransfer2BonusYear);
                    Transfer(fundWallet, _holder, noTransfer2BonusYear);
                    notransfer[_holder]=false;
                    return noTransfer2BonusYear;
                }
            } else if (now >= endTime + 31536000) {
                uint noTransferBonusYear = balances[_holder]*15 / 100;
                if (balances[fundWallet] >= noTransferBonusYear) {
                    balances[fundWallet] = balances[fundWallet] - noTransferBonusYear;
                    balances[_holder] = balances[_holder] + noTransferBonusYear;
                    assert(balances[_holder] >= noTransferBonusYear);
                    Transfer(fundWallet, _holder, noTransferBonusYear);
                    notransfer[_holder]=false;
                    return noTransferBonusYear;
                }
            }
        }
    }
    
     
    function burn(uint256 _value) onlyOwner public returns (bool){
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner] - _value;
        totalSupply = totalSupply - _value;
        Burn(burner, _value);
        return true;
    }
    
     
    function changeRefundToken() public onlyOwner {
        require(now >= endTime);
        refundToken = true;
    }
    
      
    function finishICO() public onlyOwner returns (bool) {
        uint frozenBalance = balances[msg.sender]/2;
        transfer(frozenWallet2y, frozenBalance);
        transfer(frozenWallet4y, balances[msg.sender]);
        transferAllowed = true;
        return true;
    }

     
    function refund()  canRefundToken public returns (bool){
        uint256 _value = balances[msg.sender];
        balances[msg.sender] = 0;
        totalSupply = totalSupply - _value;
        Refund(msg.sender, _value);
        return true;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Refund(address indexed refuner, uint256 value);

}