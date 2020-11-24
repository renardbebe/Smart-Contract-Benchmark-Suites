 

pragma solidity ^0.4.14;

contract DSMath {
    
     

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

     


    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }


     

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

     

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

     

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
         
         
         
         
         
         
         
         
         
         
         
         
         
         

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

contract Owned
{
    address public owner;
    
    function Owned()
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner()
    {
        if (msg.sender != owner) revert();
        _;
    }
}

contract ProspectorsCrowdsale is Owned, DSMath
{
    ProspectorsGoldToken public token;
    address public dev_multisig;  
    
    uint public total_raised;  
    uint public contributors_count = 0;  
    
    uint public constant start_time = 1502377200;  
    uint public constant end_time = 1505055600;  
    uint public constant bonus_amount = 10000000 * 10**18;  
    uint public constant start_amount = 60000000 * 10**18;  
    uint public constant price =  0.0005 * 10**18;  
    uint public constant bonus_price = 0.0004 * 10**18;  
    uint public constant goal = 2000 ether;  
    bool private closed = false;  
    
    mapping(address => uint) funded;  
    
    modifier in_time  
    {
        if (time() < start_time || time() > end_time)  revert();
        _;
    }

    function is_success() public constant returns (bool)
    {
        return closed == true && total_raised >= goal;
    }
    
    function time() public constant returns (uint)
    {
        return block.timestamp;
    }
    
    function my_token_balance() public constant returns (uint)
    {
        return token.balanceOf(this);
    }
    
     
    function available_with_bonus() public constant returns (uint)
    {
        return my_token_balance() >=  min_balance_for_bonus() ? 
                my_token_balance() - min_balance_for_bonus() 
                : 
                0;
    }
    
    function available_without_bonus() private constant returns (uint)
    {
        return min(my_token_balance(),  min_balance_for_bonus());
    }
    
    function min_balance_for_bonus() private constant returns (uint)
    {
        return start_amount - bonus_amount;
    }
    
     
    modifier has_value
    {
        if (msg.value < 0.01 ether) revert();
        _;
    }

    function init(address _token_address, address _dev_multisig) onlyOwner
    {
        if (address(0) != address(token)) revert();
        token = ProspectorsGoldToken(_token_address);
        dev_multisig = _dev_multisig;
    }
    
     
    function participate() in_time has_value private {
        if (my_token_balance() == 0 || closed == true) revert();

        var remains = msg.value;
        
          
        var can_with_bonus = wdiv(cast(remains), cast(bonus_price));
        var buy_amount = cast(min(can_with_bonus, available_with_bonus()));
        remains = sub(remains, wmul(buy_amount, cast(bonus_price)));
        
        if (buy_amount < can_with_bonus)  
        {
            var can_without_bonus = wdiv(cast(remains), cast(price));
            var buy_without_bonus = cast(min(can_without_bonus, available_without_bonus()));
            remains = sub(remains, wmul(buy_without_bonus, cast(price)));
            buy_amount = hadd(buy_amount, buy_without_bonus);
        }

        if (remains > 0) revert();

        total_raised = add(total_raised, msg.value);
        if (funded[msg.sender] == 0) contributors_count++;
        funded[msg.sender] = add(funded[msg.sender], msg.value);

        token.transfer(msg.sender, buy_amount);  
    }
    
    function refund()  
    {
        if (total_raised >= goal || closed == false) revert();
        var amount = funded[msg.sender];
        if (amount > 0)
        {
            funded[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }
    
    function closeCrowdsale()  
    {
        if (closed == false && time() > start_time && (time() > end_time || my_token_balance() == 0))
        {
            closed = true;
            if (is_success())
            {
                token.unlock();  
                if (my_token_balance() > 0)
                {
                    token.transfer(0xb1, my_token_balance());  
                }
            }
        }
        else
        {
            revert();
        }
    }
    
    function collect()  
    {
        if (total_raised < goal) revert();
        dev_multisig.transfer(this.balance);
    }

    function () payable external 
    {
        participate();
    }
    
     
    function destroy() onlyOwner
    {
        if (time() > end_time + 180 days)
        {
            selfdestruct(dev_multisig);
        }
    }
}

contract ProspectorsGoldToken {
    function balanceOf( address who ) constant returns (uint value);
    function transfer( address to, uint value) returns (bool ok);
    function unlock() returns (bool ok);
}