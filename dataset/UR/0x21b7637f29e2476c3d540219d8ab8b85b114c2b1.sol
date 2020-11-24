 

pragma solidity ^0.4.18;

 

contract Fermat {

     
    address public owner = msg.sender;
    uint releaseTime = now + 17280000;

     
    function addBalance() public payable {

    }

    function getOwner() view public returns (address)  {
        return owner;
    }

     
    function getReleaseTime() view public returns (uint)  {
        return releaseTime;
    }

     
    function withdraw() public {
        require(msg.sender == owner);
        require(now >= releaseTime);

        msg.sender.transfer(this.balance);
    }

    function getBalance() view public returns (uint256) {
        return this.balance;
    }

     
    function claim(uint256 a, uint256 b, uint256 c, uint256 n) public {
        uint256 value = solve(a, b, c, n);
        if (value == 0) {
            msg.sender.transfer(this.balance);
        }
    }



     
    function solve(uint256 a, uint256 b, uint256 c, uint256 n) pure public returns (uint256) {
        assert(n > 2);
        assert(a > 0);
        assert(b > 0);
        assert(c > 0);
        uint256 aExp = power(a, n);
        uint256 bExp = power(b, n);
        uint256 cExp = power(c, n);

        uint256 sum = add(aExp, bExp);
        uint256 difference = sub(sum, cExp);
        return difference;
    }

     
    function power(uint256 a, uint256 pow) pure public returns (uint256) {
        assert(a > 0);
        assert(pow > 0);
        uint256 result = 1;
        if (a == 0) {
            return 1;
        }
        uint256 temp;
        for (uint256 i = 0; i < pow; i++) {
            temp = result * a;
            assert((temp / a) == result);
            result = temp;
        }
        return uint256(result);
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


}