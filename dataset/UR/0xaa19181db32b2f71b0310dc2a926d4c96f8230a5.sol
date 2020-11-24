 

pragma solidity 0.4.20;

 

 

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 

 
 
 
 
contract allowanceRecipient {
    function receiveApproval(address _from, uint256 _value, address _inContract, bytes _extraData) public returns (bool);
}

 
 
contract tokenRecipient {
    function tokenFallback(address _from, uint256 _value, bytes _extraData) public returns (bool);
}

contract LuckyStrikeTokens {

     
    using SafeMath for uint256;

     

     
     
    string public name = "LuckyStrikeTokens";

     
     
    string public symbol = "LST";

     
     
    uint8 public decimals = 0;

     
     
    uint256 public totalSupply;

     
     
    mapping(address => uint256) public balanceOf;

     
     
    mapping(address => mapping(address => uint256)) public allowance;

     

     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed spender, uint256 value);

     
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes _extraData);

    address public owner;  
    address public team;  

    uint256 public invested;  
    uint256 public hardCap;  

    uint256 public tokenSaleStarted;  
    uint256 public salePeriod;  
    bool public tokenSaleIsRunning = true;

     
     
     
    address admin;  
    function LuckyStrikeTokens() public {
        admin = msg.sender;
    }

    function init(address luckyStrikeContractAddress) public {

        require(msg.sender == admin);
        require(tokenSaleStarted == 0);
        require(luckyStrikeContractAddress != address(0));

         
        hardCap = 4500 ether;
        salePeriod = 200 days;

         
         
         
         

        team = 0x0bBAb60c495413c870F8cABF09436BeE9fe3542F;

        balanceOf[0x7E6CdeE9104f0d93fdACd550304bF36542A95bfD] = 33040000;
        Transfer(address(0), 0x7E6CdeE9104f0d93fdACd550304bF36542A95bfD, 33040000);

        balanceOf[0x21F73Fc4557a396233C0786c7b4d0dDAc6237582] = 8260000;
        Transfer(address(0), 0x21F73Fc4557a396233C0786c7b4d0dDAc6237582, 8260000);

        balanceOf[0x23a91B45A1Cc770E334D81B24352C1C06C4830F6] = 26600000;
        Transfer(address(0), 0x23a91B45A1Cc770E334D81B24352C1C06C4830F6, 26600000);

        balanceOf[0x961f5a8B214beca13A0fdB0C1DD0F40Df52B8D55] = 2100000;
        Transfer(address(0), 0x961f5a8B214beca13A0fdB0C1DD0F40Df52B8D55, 2100000);

        totalSupply = 70000000;

        owner = luckyStrikeContractAddress;
        tokenSaleStarted = block.timestamp;
    }

     
    event IncomePaid(address indexed to, uint256 tokensBurned, uint256 sumInWeiPaid);

     
    function takeIncome(uint256 valueInTokens) public returns (bool) {

        require(!tokenSaleIsRunning);
        require(this.balance > 0);
        require(totalSupply > 0);
        require(balanceOf[msg.sender] > 0);
        require(valueInTokens <= balanceOf[msg.sender]);

         
        uint256 sumToPay = (this.balance).mul(valueInTokens).div(totalSupply);

        totalSupply = totalSupply.sub(valueInTokens);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(valueInTokens);

        msg.sender.transfer(sumToPay);

        IncomePaid(msg.sender, valueInTokens, sumToPay);

        return true;
    }

     
    event WithdrawalByTeam(uint256 value, address indexed to, address indexed triggeredBy);

    function withdrawAllByTeam() public {
        require(msg.sender == team);
        require(totalSupply == 0 && !tokenSaleIsRunning);
        uint256 sumToWithdraw = this.balance;
        team.transfer(sumToWithdraw);
        WithdrawalByTeam(sumToWithdraw, team, msg.sender);
    }

     
     

     
    function transfer(address _to, uint256 _value) public returns (bool){
        return transferFrom(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

        if (_to == address(this)) {
             
            require(_from == msg.sender);
            return takeIncome(_value);
        }

         
         

         
        require(_value >= 0);

         
        require(msg.sender == _from || _value <= allowance[_from][msg.sender]);
        require(_to != 0);

         
        require(_value <= balanceOf[_from]);

         
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
         
         
        balanceOf[_to] = balanceOf[_to].add(_value);

         
        if (_from != msg.sender) {
             
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

         
        Transfer(_from, _to, _value);

        return true;
    }  

     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool){
        require(_value >= 0);
        allowance[msg.sender][_spender] = _value;
         
        Approval(msg.sender, _spender, _value);
        return true;
    }

     

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {

        approve(_spender, _value);

         
        allowanceRecipient spender = allowanceRecipient(_spender);

         
         
         
        if (spender.receiveApproval(msg.sender, _value, this, _extraData)) {
            DataSentToAnotherContract(msg.sender, _spender, _extraData);
            return true;
        }
        return false;
    }  

     
    function approveAllAndCall(address _spender, bytes _extraData) public returns (bool success) {
        return approveAndCall(_spender, balanceOf[msg.sender], _extraData);
    }

     
    function transferAndCall(address _to, uint256 _value, bytes _extraData) public returns (bool success){

        transferFrom(msg.sender, _to, _value);

        tokenRecipient receiver = tokenRecipient(_to);

        if (receiver.tokenFallback(msg.sender, _value, _extraData)) {
            DataSentToAnotherContract(msg.sender, _to, _extraData);
            return true;
        }
        return false;
    }  

     
    function transferAllAndCall(address _to, bytes _extraData) public returns (bool success){
        return transferAndCall(_to, balanceOf[msg.sender], _extraData);
    }

     

    event NewTokensMinted(
        address indexed to,  
        uint256 invested,  
        uint256 tokensForInvestor,  
        address indexed by,  
        bool indexed tokenSaleFinished,  
        uint256 totalInvested  
    );

     
    function mint(address to, uint256 value, uint256 _invested) public returns (bool) {

        require(msg.sender == owner);

        require(tokenSaleIsRunning);
        require(value >= 0);
        require(_invested >= 0);
        require(to != owner && to != 0);
         

        balanceOf[to] = balanceOf[to].add(value);
        totalSupply = totalSupply.add(value);
        invested = invested.add(_invested);

        if (invested >= hardCap || now.sub(tokenSaleStarted) > salePeriod) {
            tokenSaleIsRunning = false;
        }

        NewTokensMinted(
            to,  
            _invested,  
            value,  
            msg.sender,  
            !tokenSaleIsRunning,  
            invested  
        );

        Transfer(address(0), to, value);

        return true;
    }

     
     
     

    function transferIncome() public payable {
    }

}