trad:
	cmake -Bbuild-trad -S. -DMORAN_VARIANT=trad
	cmake --build build-trad

simp:
	cmake -Bbuild-simp -S. -DMORAN_VARIANT=simp
	cmake --build build-simp

clean:
	rm -rf build build-simp build-trad

.PHONY: trad simp trad-demo simp-demo clean
