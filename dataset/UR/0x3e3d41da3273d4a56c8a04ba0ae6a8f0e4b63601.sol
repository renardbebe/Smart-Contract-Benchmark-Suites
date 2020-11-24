 
contract EtheleGenerator {
    address private _fire;
    address private _earth;
    address private _metal;
    address private _water;
    address private _wood;
    address private _yin;
    address private _yang;

    uint256 private _step;  

    uint256 private constant LAUNCH_TIME = 1565438400;  

     
     
    constructor() public {
        _step = 0;
    }

    function getLaunchTime() public pure returns (uint256) {
        return LAUNCH_TIME;
    }

    function step() public {
        require(_step <= 3 && LAUNCH_TIME < block.timestamp);

        if (_step == 0) {
            _fire = address(new EtheleToken("Ethele Fire", "EEFI"));
            _earth = address(new EtheleToken("Ethele Earth", "EEEA"));
        } else if (_step == 1) {
            _metal = address(new EtheleToken("Ethele Metal", "EEME"));
            _water = address(new EtheleToken("Ethele Water", "EEWA"));
        } else if (_step == 2) {
            _wood = address(new EtheleToken("Ethele Wood", "EEWO"));
            _yin = address(new EtheleToken("Ethele Yin", "EEYI"));
        } else if (_step == 3) {
            _yang = address(new EtheleToken("Ethele Yang", "EEYA"));
             
            EtheleToken(_fire).setTransmuteSources12(_metal, _wood);
            EtheleToken(_earth).setTransmuteSources12(_water, _fire);
            EtheleToken(_metal).setTransmuteSources12(_wood, _earth);
            EtheleToken(_water).setTransmuteSources12(_fire, _metal);
            EtheleToken(_wood).setTransmuteSources12(_earth, _water);
            
             
            EtheleToken(_fire).setTransmuteSources34(_yin, _yang);
            EtheleToken(_earth).setTransmuteSources34(_yin, _yang);
            EtheleToken(_metal).setTransmuteSources34(_yin, _yang);
            EtheleToken(_water).setTransmuteSources34(_yin, _yang);
            EtheleToken(_wood).setTransmuteSources34(_yin, _yang);

             
            EtheleToken(_metal).allowBurnsFrom(_fire);
            EtheleToken(_wood).allowBurnsFrom(_fire);
            EtheleToken(_water).allowBurnsFrom(_earth);
            EtheleToken(_fire).allowBurnsFrom(_earth);
            EtheleToken(_wood).allowBurnsFrom(_metal);
            EtheleToken(_earth).allowBurnsFrom(_metal);
            EtheleToken(_fire).allowBurnsFrom(_water);
            EtheleToken(_metal).allowBurnsFrom(_water);
            EtheleToken(_earth).allowBurnsFrom(_wood);
            EtheleToken(_water).allowBurnsFrom(_wood);

             
             
            EtheleToken(_yin).allowBurnsFrom(_fire);
            EtheleToken(_yin).allowBurnsFrom(_earth);
            EtheleToken(_yin).allowBurnsFrom(_metal);
            EtheleToken(_yin).allowBurnsFrom(_water);
            EtheleToken(_yin).allowBurnsFrom(_wood);
            EtheleToken(_yang).allowBurnsFrom(_fire);
            EtheleToken(_yang).allowBurnsFrom(_earth);
            EtheleToken(_yang).allowBurnsFrom(_metal);
            EtheleToken(_yang).allowBurnsFrom(_water);
            EtheleToken(_yang).allowBurnsFrom(_wood);
        }

        _step += 1;
    }

    function getStep() public view returns (uint256) {
        return _step;
    }
    function fire() public view returns (address) {
        return _fire;
    }
    function earth() public view returns (address) {
        return _earth;
    }
    function metal() public view returns (address) {
        return _metal;
    }
    function water() public view returns (address) {
        return _water;
    }
    function wood() public view returns (address) {
        return _wood;
    }
    function yin() public view returns (address) {
        return _yin;
    }
    function yang() public view returns (address) {
        return _yang;
    }
}
