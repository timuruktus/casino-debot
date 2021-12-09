pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "./core/Terminal.sol";
import "./core/Sdk.sol";
import "./core/AddressInput.sol";
import "./core/ConfirmInput.sol";
import "./core/Debot.sol";
import "./core/Menu.sol";
import "/CasinoContractInterface.sol";

contract CasinoDebot is Debot{

    uint userPubKey;
    address private casinoContractAddress;
    Session private _currentSession;

    function start() public override{
        Terminal.input(tvm.functionId(savePublicKey),"Hello. Please, enter your public key",false);
    }

    function setCasinoAddress(address casinoAddress) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        casinoContractAddress = casinoAddress;
    }

    function savePublicKey(string value) public {
        (uint res, bool valid) = stoi("0x"+value);
        if(valid) {
            userPubKey = res;
            getCurrentSession();
        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }

    function getCurrentSession() public{
        optional(uint256) none;
        CasinoContractInterface(casinoContractAddress).getCurrentSession{
            extMsg: true,
            abiVer: 2,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showMenu),
            onErrorId: tvm.functionId(getCurrentSession)
        }();
    }

    function showMenu(Session currentSession){
        _currentSession = currentSession;
        uint[] currentBets = currentSession.bets;
        uint betsSum = 0;
        for(uint bet : currentBets) betsSum += bet;
        string summary = format("Current game stat: Current Players - {}. Bets sum - {}", currentBets.length(), betsSum); 
        
        Terminal.print(0, "Current game stat: ");


    }

    /// @notice Returns list of interfaces used by DeBot.
    function getRequiredInterfaces() public view override returns (uint256[] interfaces){
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function getDebotInfo() public functionID(0xDEB) view override returns(
        string name, string version, string publisher, string caption, string author,
        address support, string hello, string language, string dabi, bytes icon){
        name = "Casino DeBot";
        version = "1.0.0";
        publisher = "Timur Khasanov";
        caption = "Welcome to casino debot. Here you can post your bet.";
        author = "Timur Khasanov";
        support = address.makeAddrStd(0, 0x1e3713373c839489cd84f0745d7f98a0ba3bcdbd91a56ac30c79f769303ec603);
        hello = "Welcome to casino debot. Here you can post your bet and try to win others bets. The more you post the more chances you get.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = "";
    }



}