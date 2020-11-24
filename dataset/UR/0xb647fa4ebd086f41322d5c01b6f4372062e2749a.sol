 

contract TempoToken is StandardBurnableToken {
    using SafeMath for uint256;
    constructor (uint256 initialSupply, address _authRepoAddress) public {
        totalSupply_ = initialSupply;
        balances[msg.sender] = initialSupply;
        authRepoAddress = _authRepoAddress;
    }


    bool public authorization;
    address authRepoAddress;

    event Transfer(
                   address indexed from,
                   address indexed to,
                   uint256 value
                   );


    function getAuthorization() public returns (bool) {
        AuthRepo instanceAuthRepo = AuthRepo(authRepoAddress);
        return instanceAuthRepo.authorizeContract();
    }

    function transferFrom(
                          address _from,
                          address _to,
                          uint256 _value
                          )
        public
        returns (bool)
    {
        require(_value <= balances[_from]);
         
        require(_to != address(0));
        authorization = getAuthorization();
         
        require(authorization == true);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
         
        emit Transfer(_from, _to, _value);
        return true;
    }
}
