 

pragma solidity ^0.4.18;


 
contract AbstractToken {

    function balanceOf(address owner) public view returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}


contract Owned {

    address public owner = msg.sender;
    address public potentialOwner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPotentialOwner {
        require(msg.sender == potentialOwner);
        _;
    }

    event NewOwner(address old, address current);
    event NewPotentialOwner(address old, address potential);

    function setOwner(address _new)
        public
        onlyOwner
    {
        NewPotentialOwner(owner, _new);
        potentialOwner = _new;
    }

    function confirmOwnership()
        public
        onlyPotentialOwner
    {
        NewOwner(owner, potentialOwner);
        owner = potentialOwner;
        potentialOwner = 0;
    }
}


 
contract StandardToken is AbstractToken, Owned {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}


 
 
contract SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint a, uint b) internal pure returns (uint) {
        uint c = a ** b;
        assert(c >= a);
        return c;
    }
}


 
 
contract Token is StandardToken, SafeMath {

     
    uint public creationTime;

    function Token() public {
        creationTime = now;
    }


     
    function transferERC20Token(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint balance = AbstractToken(tokenAddress).balanceOf(this);
        return AbstractToken(tokenAddress).transfer(owner, balance);
    }

     
    function withDecimals(uint number, uint decimals)
        internal
        pure
        returns (uint)
    {
        return mul(number, pow(10, decimals));
    }
}


 
 
contract TokenboxToken is Token {

     
    string constant public name = "Tokenbox";
 
    string constant public symbol = "TBX";
    uint8 constant public decimals = 18;

     
    address constant public foundationReserve = address(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

     
    address constant public icoAllocation = address(0x1111111111111111111111111111111111111111);

     
    address constant public preIcoAllocation = address(0x2222222222222222222222222222222222222222);

     
    uint256 constant public vestingDateEnd = 1543406400;

     
    uint256 public totalPicoUSD = 0;
    uint8 constant public usdDecimals = 12;

     
    address public multisig;

    bool public migrationCompleted = false;

     
    event InvestmentInETH(address investor, uint256 tokenPriceInWei, uint256 investedInWei, uint256 investedInPicoUsd, uint256 tokensNumber, uint256 originalTransactionHash);
    event InvestmentInBTC(address investor, uint256 tokenPriceInSatoshi, uint256 investedInSatoshi, uint256 investedInPicoUsd, uint256 tokensNumber, string btcAddress);
    event InvestmentInUSD(address investor, uint256 tokenPriceInPicoUsd, uint256 investedInPicoUsd, uint256 tokensNumber);
    event PresaleInvestment(address investor, uint256 investedInPicoUsd, uint256 tokensNumber);

     
    function TokenboxToken(address _multisig, uint256 _preIcoTokens)
        public
    {
         
        totalSupply = withDecimals(31000000, decimals);

        uint preIcoTokens = withDecimals(_preIcoTokens, decimals);

         
        balances[preIcoAllocation] = preIcoTokens;

         
        balances[foundationReserve] = 0;

         
        balances[icoAllocation] = div(mul(totalSupply, 75), 100) - preIcoTokens;

        multisig = _multisig;
    }

    modifier migrationIsActive {
        require(!migrationCompleted);
        _;
    }

    modifier migrationIsCompleted {
        require(migrationCompleted);
        _;
    }

     
    function ethInvestment(address investor, uint256 tokenPriceInPicoUsd, uint256 investedInWei, uint256 originalTransactionHash, uint256 usdToWei)
        public
        migrationIsActive
        onlyOwner
    {
        uint tokenPriceInWei = div(mul(tokenPriceInPicoUsd, usdToWei), pow(10, usdDecimals));

         
        uint256 tokensNumber = div(withDecimals(investedInWei, decimals), tokenPriceInWei);

         
        require(balances[icoAllocation] >= tokensNumber);

        uint256 investedInPicoUsd = div(withDecimals(investedInWei, usdDecimals), usdToWei);

        usdInvestment(investor, investedInPicoUsd, tokensNumber);
        InvestmentInETH(investor, tokenPriceInWei, investedInWei, investedInPicoUsd, tokensNumber, originalTransactionHash);
    }

     
    function btcInvestment(address investor, uint256 tokenPriceInPicoUsd, uint256 investedInSatoshi, string btcAddress, uint256 usdToSatoshi)
        public
        migrationIsActive
        onlyOwner
    {
        uint tokenPriceInSatoshi = div(mul(tokenPriceInPicoUsd, usdToSatoshi), pow(10, usdDecimals));

         
        uint256 tokensNumber = div(withDecimals(investedInSatoshi, decimals), tokenPriceInSatoshi);

         
        require(balances[icoAllocation] >= tokensNumber);

        uint256 investedInPicoUsd = div(withDecimals(investedInSatoshi, usdDecimals), usdToSatoshi);

        usdInvestment(investor, investedInPicoUsd, tokensNumber);
        InvestmentInBTC(investor, tokenPriceInSatoshi, investedInSatoshi, investedInPicoUsd, tokensNumber, btcAddress);
    }

     
    function wireInvestment(address investor, uint256 tokenPriceInUsdCents, uint256 investedInUsdCents)
        public
        migrationIsActive
        onlyOwner
     {

       uint256 tokensNumber = div(withDecimals(investedInUsdCents, decimals), tokenPriceInUsdCents);

        
       require(balances[icoAllocation] >= tokensNumber);

        
       uint256 investedInPicoUsd = withDecimals(investedInUsdCents, usdDecimals - 2);
       uint256 tokenPriceInPicoUsd = withDecimals(tokenPriceInUsdCents, usdDecimals - 2);

       usdInvestment(investor, investedInPicoUsd, tokensNumber);

       InvestmentInUSD(investor, tokenPriceInPicoUsd, investedInPicoUsd, tokensNumber);
    }

     
    function usdInvestment(address investor, uint256 investedInPicoUsd, uint256 tokensNumber)
        private
    {
      totalPicoUSD = add(totalPicoUSD, investedInPicoUsd);

       
      balances[icoAllocation] -= tokensNumber;
      balances[investor] += tokensNumber;
      Transfer(icoAllocation, investor, tokensNumber);
    }

     
    function migrateTransfer(address _from, address _to, uint256 amount, uint256 originalTransactionHash)
        public
        migrationIsActive
        onlyOwner
    {   
        require(balances[_from] >= amount);
        balances[_from] -= amount;
        balances[_to] += amount;
        Transfer(_from, _to, amount);
    }

     
    function preIcoInvestment(address investor, uint256 investedInUsdCents, uint256 tokensNumber)
        public
        migrationIsActive
        onlyOwner
    {
      uint256 tokensNumberWithDecimals = withDecimals(tokensNumber, decimals);

       
      require(balances[preIcoAllocation] >= tokensNumberWithDecimals);

       
      balances[preIcoAllocation] -= tokensNumberWithDecimals;
      balances[investor] += tokensNumberWithDecimals;
      Transfer(preIcoAllocation, investor, tokensNumberWithDecimals);

      uint256 investedInPicoUsd = withDecimals(investedInUsdCents, usdDecimals - 2);

       
      totalPicoUSD = add(totalPicoUSD, investedInPicoUsd);

      PresaleInvestment(investor, investedInPicoUsd, tokensNumberWithDecimals);
    }


     
    function allowToWithdrawFromReserve()
        public
        migrationIsCompleted
        onlyOwner
    {
        require(now >= vestingDateEnd);

         
        allowed[foundationReserve][msg.sender] = balanceOf(foundationReserve);
    }


     
    function withdrawFromReserve(uint amount)
        public
        migrationIsCompleted
        onlyOwner
    {
        require(now >= vestingDateEnd);

         
        require(transferFrom(foundationReserve, multisig, amount));
    }

     
    function changeMultisig(address _multisig)
        public
        onlyOwner
    {
        multisig = _multisig;
    }

    function transfer(address _to, uint256 _value)
        public
        migrationIsCompleted
        returns (bool success) 
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        migrationIsCompleted
        returns (bool success)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
     
    function finaliseICO()
        public
        migrationIsActive
        onlyOwner
    {
         
        uint256 tokensSold = sub(div(mul(totalSupply, 75), 100), balanceOf(icoAllocation));

         
        totalSupply = div(mul(tokensSold, 100), 75);

         
        balances[multisig] = div(mul(totalSupply, 125), 1000);
        Transfer(icoAllocation, multisig, balanceOf(multisig));

         
        balances[foundationReserve] = div(mul(totalSupply, 125), 1000);
        Transfer(icoAllocation, foundationReserve, balanceOf(foundationReserve));

         
        Transfer(icoAllocation, 0x0000000000000000000000000000000000000000, balanceOf(icoAllocation));
        balances[icoAllocation] = 0;

        migrationCompleted = true;
    }

    function totalUSD()
      public view
      returns (uint)
    {
       return div(totalPicoUSD, pow(10, usdDecimals));
    }
}