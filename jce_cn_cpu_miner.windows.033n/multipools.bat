@echo off
rem     This is an example of multi-pools autoswitch script.
rem     You can change and add coins and pools as you whish.
rem     All wallets displayed here are the dev donation wallets, as an EXAMPLE
rem     Replace them with yours, unless you want to do an explicit donation.
rem

rem Customize password if needed
set PASSWORD=x

rem Uncomment to use SSL
rem   set SSL=--ssl

rem 
rem     JCE will mine for the desired time, or until an error occurs, then switch to
rem     the next coin, and repeat.
rem 
rem     The bat script is very sensitive to indentation and escape characters,
rem     don't play with them or you'll get obscure errors.


rem        Mining time (mn)   POOL:PORT                            Wallet
rem        ================ ================                    ===============================================================================================
set LIST=^
             20             xmrpool.eu:3333                     43iTLAWVGiv5T53hXS7S35ehZtvJ7zmP6gnyMqoCP66gPoqRNiSY34TXhiaQEGiCaMe79YVzRicRA1wAnYsvTNTEJ5ojZPu  ;^
             15             pool.leviarcoin.hashvault.pro:3333  LrsY2Y9L1jyZbfL9hbzfH4g2nRXfzkRoWjHv4rBLjETvQsLL7wcgRQziAjTpzva3A5FSedww1md9a1D5BvQpSfoTHNbfZKj  ;^
             25             ipbc.ingest.cryptoknight.cc:4461    bxc2RN85CG1iZZoqvRgmfNehToo7xsSPY8Eo5Kjc7mDAi7HXxXuvzoDUy2eb2yFaWGTbu7rGGKWUBcjRAtauHtBi393s77hiv  ;^
;
            
			

rem ==================================================================
rem Do NOT change anything under this line or you may break the script.
rem ==================================================================

rem Select 32 or 64 bits
if defined BITS goto :SkipBits
set BITS=64
if x%PROCESSOR_ARCHITECTURE%==xx86 set BITS=32
:SkipBits

set LF=^


setlocal EnableDelayedExpansion
for %%L in ("!LF!") do set "LIST=!LIST:;=%%~L!"
:Reloop
for /F "delims=;" %%i in ("!LIST!") do for /F "tokens=1-3" %%a in ("%%i") do jce_cn_cpu_miner%BITS%.exe --auto --any --low -o %%b -u %%c -p %PASSWORD% %SSL% -q --autoclose %%a
goto :Reloop
